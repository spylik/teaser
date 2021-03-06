-module(tutils).

-compile(export_all).
-compile(nowarn_export_all).
-include("utils.hrl").

-include_lib("eunit/include/eunit.hrl").

-spec batch_receiver_and_loop() -> Result when
    Result      :: {ReceiverPid, WorkerPid},
    ReceiverPid :: pid(),
    WorkerPid   :: pid().

batch_receiver_and_loop() ->
    Keeper = spawn_wait_loop('keep'),
    {Keeper, batch_loop(Keeper)}.

-spec batch_receiver_and_loop(Topic) -> PidOfKeeper when
    Topic           :: erlroute:topic(),
    PidOfKeeper     :: pid().

batch_receiver_and_loop(Topic) ->
    Keeper = spawn_wait_loop('keep'),
    batch_loop(Topic, Keeper),
    Keeper.

-spec read_receiver(KeeperPid) -> Result when
    KeeperPid       :: pid(),
    Result          :: [] | [term()] | timeout_in_receiver.

read_receiver(KeeperPid) ->
    KeeperPid ! {'read', self()},
    receive
        Data -> Data
        after 15 -> timeout_in_receiver
    end.


-spec read_and_flush_receiver(KeeperPid) -> Result when
    KeeperPid       :: pid(),
    Result          :: [] | [term()] | timeout_in_receiver.

read_and_flush_receiver(KeeperPid) ->
    KeeperPid ! {'read_and_flush', self()},
    receive
        Data -> Data
        after 15 -> timeout_in_receiver
    end.


-spec read_and_shutdown_receiver(KeeperPid) -> Result when
    KeeperPid       :: pid(),
    Result          :: [] | [term()] | timeout_in_receiver.

read_and_shutdown_receiver(KeeperPid) ->
    KeeperPid ! {'read_and_die', self()},
    receive
        Data -> Data
        after 15 -> timeout_in_receiver
    end.

batch_loop(ReceiverPid) when is_pid(ReceiverPid) ->
    spawn_wait_loop(ReceiverPid);

% batch receive loop in separate process (awaiting message in topic)
batch_loop(Topic) when is_binary(Topic) ->
    WorkerPid = spawn_wait_loop(self()),
    erlroute:sub([{topic, Topic}], WorkerPid),
    WorkerPid.
batch_loop(Topic, ReceiverPid) ->
    erlroute:sub([{topic, Topic}], spawn_wait_loop(ReceiverPid)),
    ReceiverPid.

% recieve loop
recieve_loop() -> recieve_loop([], 15, 'got').

recieve_loop(Acc) when is_list(Acc) ->
    recieve_loop(Acc, 15, 'got').

recieve_loop(Acc, Timeout) -> recieve_loop(Acc, Timeout, 'got').

recieve_loop(Acc, Timeout, WaitFor) ->
    receive
        {WaitFor, Data} -> recieve_loop([Data|Acc],Timeout,WaitFor)
        after Timeout -> lists:reverse(Acc)
    end.

% spawn wait_msg_loop
spawn_wait_loop(SendToPid) -> spawn(?MODULE, wait_msg_loop, [SendToPid]).

% waiting loop
wait_msg_loop(SendToPidOrKeep) -> wait_msg_loop(SendToPidOrKeep, 'got', []).
wait_msg_loop(SendToPidOrKeep, WaitFor, Acc) ->
    receive
        stop -> true;
        {'read', Pid} -> Pid ! Acc, wait_msg_loop(SendToPidOrKeep, WaitFor, Acc);
        {'read_and_flush', Pid} -> Pid ! Acc, wait_msg_loop(SendToPidOrKeep, WaitFor, []);
        {'read_and_die', Pid} -> Pid ! Acc, true;
        Msg when is_pid(SendToPidOrKeep) ->
            case process_info(SendToPidOrKeep) of
                undefined -> true;
                _ ->
                    SendToPidOrKeep ! {WaitFor, Msg},
                    wait_msg_loop(SendToPidOrKeep, WaitFor, Acc)
            end;
        {WaitFor, Msg} when SendToPidOrKeep =:= 'keep' ->
            wait_msg_loop(SendToPidOrKeep, WaitFor, [Msg | Acc])
    end.

% spawn wait_msg_loop
spawn_wait_loop_max(Max) -> spawn_wait_loop_max(Max, 15).
spawn_wait_loop_max(Max,Timeout) -> spawn(?MODULE, wait_msg_loop_max, [[], Timeout, Max, 0, self()]).

% receive loop with maximum messages
wait_msg_loop_max(Acc, Timeout, Max, Current, ReportTo) when Max > Current ->
    receive
        stop -> true;
        Data -> wait_msg_loop_max([Data|Acc], Timeout, Max, Current+1, ReportTo)
    after Timeout -> ReportTo ! {self(), Acc}
    end;
wait_msg_loop_max(Acc, _Timeout, _Max, _Current, ReportTo) -> ReportTo ! {self(), Acc}.



% start what we need and return it to cleanup/1
setup_start(Parameters) ->
    error_logger:tty(false),
    Apps =
        case lists:keyfind('apps', 1, Parameters) of
            {'apps', App2Start} ->
                _ = lists:map(fun(App) -> application:ensure_all_started(App) end, App2Start),
                App2Start;
            false -> []
        end,
    Gserverservers =
        case lists:keyfind('gservers', 1, Parameters) of
            {'gservers', GServers} ->
                GServers;
            false -> []
        end,
    [{'apps',Apps},{'gservers',Gserverservers}].

% stop applications, gen_servers
cleanup_stop(Parameters) ->
    _Apps =
        case lists:keyfind('apps', 1, Parameters) of
            {'apps', App2Stop} ->
                lists:map(fun(App) -> application:stop(App) end, lists:reverse(App2Stop));
            false -> []
        end,
    _gserverservers =
        case lists:keyfind('gservers', 1, Parameters) of
            {'gservers', GServers} ->
                lists:map(fun(GServer) -> gen_server:stop(GServer) end, lists:reverse(GServers));
            false -> []
        end.

% disable output
disable_output() ->
    error_logger:tty(false).

