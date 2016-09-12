-module(tutils).

-compile(export_all).
-include("utils.hrl").

% recieve loop
recieve_loop() -> recieve_loop([], 15). 

recieve_loop(Acc) ->
    recieve_loop(Acc, 15).

recieve_loop(Acc, Timeout) ->
    receive   
        {got, Data} -> recieve_loop([Data|Acc],Timeout)
        after Timeout -> lists:reverse(Acc)
    end.

spawn_wait_loop(SendToPid) -> spawn_link(?MODULE, wait_msg_loop, [SendToPid]).

% waiting loop
wait_msg_loop(SendToPid) ->
    receive
        stop -> true;
        Msg ->
%            ?debug("got msg ~p, sending to pid",[Msg]),
            SendToPid ! {got, Msg},
            wait_msg_loop(SendToPid)
    end.

disable_output() ->
    error_logger:tty(false).
