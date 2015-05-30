

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_error)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_session)).
:- use_module(library(http/js_write)).
:- use_module(library(http/http_files)).

http:location(files, '/f', []).

:- http_handler('/', home_page, []).
:- http_handler(files(.), http_reply_from_files('test_files', []), [prefix]).

server(Port) :-
        http_server(http_dispatch, [port(Port)]),
	format("Server should be on port 5000 to work with google settings- is it?").

/* The implementation of /. The single argument provides the request
details, which we ignore for now. Our task is to write a CGI-Document:
a number of name: value -pair lines, followed by two newlines, followed
by the document content, The only obligatory header line is the
:- use_module(library(http/http_session)).Content-type: <mime-type> header.
Printing is done with reply_html_page, which handles the headers and
the head and body tags, the doctype, etc. */

home_page(Request) :-
	nick_name(Nick),
	reply_html_page(
	   [title('Oauth Test'),
	   script([type='text/javascript',
		    src='//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js'],[]),
	   script([type='text/javascript',
		    src='//apis.google.com/js/platform.js?onload=start'],[]),
	   script([type='text/javascript',
		    src='https://api.tiles.mapbox.com/mapbox.js/v2.1.9/mapbox.js'],[]),
	    \call_back_script
	   ],
	    [h1('hello'),
	    p('~w, we are glad your spirit is present with us'-[Nick]),
	    \google_loginButton
	    ]).

call_back_script -->
	js_script({|javascript||
		      console.log("script runs");
		      function signInCallback(authResult) {
                        console.log("got to call back");
                        if (authResult['code']) {
                         console.log("has code");
                         console.log(authResult['code']);
			 $('#signInButton').attr('style','display: none');
			}
		      }

		      |}).


google_loginButton -->
	html([div([id="signInButton"],[
		  span([
		     class="g-signin",
		     data-scope="openid email",
		     data-clientid="124024716168-p5lvtlj5jinp9u912s3f7v3a5cuvj2g8.apps.googleusercontent.com",
		     data-redirecturi="postmessage",
		     data-accesstype="offline",
		     data-cookiepolicy="single_host_origin",
		     data-callback="signInCallback",
		     data-approvalprompt="force"],[])
		  ])]).


nick_name(Nick) :-
	http_session_data(nick_name(Nick)),!.

nick_name(Nick) :-
	nick_list(NickList),
	random_member(Nick, NickList),
	http_session_assert(nick_name(Nick)).

nick_list([
    'Gentle One',
    'Blessed Spirit',
    'Wise Soul',
    'Wise One',
    'Beloved Friend'
	  ]).


