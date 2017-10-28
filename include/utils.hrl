% debug macros (development only, will not available once compiled in release mode)
% todo: rid macros from the code with parse transform for release mode
-ifndef(release).
    -define(here, error_logger:info_msg("(~p)~p: we are here", [?LINE,?MODULE]), true).
    -define(dump_to_file(Data, Filename),
        file:write_file(Filename, io_lib:fwrite("~s~n",[Data]))
    ).
    -define(debug(Msg),
        case is_binary(Msg) of
            false ->
                error_logger:info_msg("(~p)~p: ~p is ~p", [?LINE,?MODULE,??Msg,Msg]);
            true ->
                error_logger:info_msg("(~p)~p: ~p is ~s", [?LINE,?MODULE,??Msg,Msg])
        end, true).
    -define(debug(Msg,Arg),
        error_logger:info_msg(lists:concat(["(~p)~p: ", Msg]), lists:append([?LINE,?MODULE], Arg)), true
    ).
-else.
    -define(here, true).
    -define(dump_to_file(Data, Filename), true).
    -define(debug(Msg), true).
    -define(debug(Msg,Arg), true).
-endif.

% warning macros (will be available both in development and release mode)
-define(warning(Msg),
        error_logger:warning_msg("(~p)~p: ~p", [?LINE,?MODULE,Msg])
    ).
-define(warning(Msg,Arg),
        error_logger:warning_msg(lists:concat(["(~p)~p: ", Msg]), lists:append([?LINE,?MODULE], Arg))
    ).

% info macros (will be available both in development and release mode)
-define(info(Msg),
        case is_list(Msg) of
            false ->
                error_logger:info_msg("(~p)~p: ~p", [?LINE,?MODULE,Msg]);
            true ->
                error_logger:info_msg("(~p)~p: ~s", [?LINE,?MODULE,Msg])
        end
    ).
-define(info(Msg,Arg),
        error_logger:info_msg(lists:concat(["(~p)~p: ", Msg]), lists:append([?LINE,?MODULE], Arg))
    ).

% error macros (will be available both in development and release mode)
-define(error(Msg),
        case is_list(Msg) of
            false ->
                error_logger:error_msg("(~p)~p: ~p", [?LINE,?MODULE,Msg]);
            true ->
                error_logger:error_msg("(~p)~p: ~s", [?LINE,?MODULE,Msg])
        end
    ).

-define(error(Msg,Arg),
        error_logger:error_msg(lists:concat(["(~p)~p: ", Msg]), lists:append([?LINE,?MODULE], Arg))
    ).

% got undefined message with standart format
-define(undefined(Arg),
        {current_function, {M, F, A}} = process_info(self(), current_function),
        RegisteredName = case process_info(self(), registered_name) of
            [] -> unregistered;
            {registered_name, Name} -> Name
        end,
        error_logger:warning_msg("(~p)~p:~p/~p (~p, ~p) something undefined:~n~p", [?LINE,M,F,A,self(),RegisteredName,Arg])
    ).
% got undefined message with custom format
-define(undefined(Msg,Arg),
        {current_function, {M, F, A}} = process_info(self(), current_function),
        RegisteredName = case process_info(self(), registered_name) of
            [] -> unregistered;
            {registered_name, Name} -> Name
        end,
        error_logger:warning_msg(lists:concat(["(~p)~p:~p/~p (~p, ~p)", Msg]), [?LINE,M,F,A,self(),RegisteredName,Arg])
    ).
