

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_error)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_session)).
:- use_module(library(http/js_write)).
:- use_module(library(http/http_files)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_client)).

http:location(files, '/f', []).

:- http_handler('/', home_page, []).
:- http_handler('/gconnect', gconnect, []).

:- http_handler(files(.), http_reply_from_files('test_files', []), [prefix]).

server(Port) :-
        http_server(http_dispatch, [port(Port)]),
	format("Server should be on port 5000 to work with google settings- is it?").

read_client_secrets(MyWeb,Client_Id,Client_Secret) :-
	open('client_secrets.json',read,Stream),
	json_read_dict(Stream,Dict),
	_{web:MyWeb} :< Dict,
	_{
	    auth_provider_x509_cert_url:Auth_url,
	    auth_uri:Auth_uri,
	    client_email:Client_email,
	    client_id:Client_Id,
	    client_secret:Client_Secret,
	    client_x509_cert_url:Client_cert_url,
	    javascript_origins:Javascript_origins,
	    redirect_uris: Redirect_uris,
	    token_uri:Token_Uri
	} :<MyWeb,
	close(Stream).

post_to_google(Reply,Code,Client_Id,Client_Secret):-
	    Grant_type=authorization_code,
	    http_post(
             'http://postcatcher.in/catchers/5569b2144bc773030000825a',
		form([
		  code=Code,
		  redirect_uri='http://localhost:5000',
		  client_id=Client_Id,
	          %scope=Scope,
		  client_secret=Client_Secret,
		  grant_type=Grant_type
	      ]),
              Reply,
             []
          ).
   %term_to_atom(Term,Reply).


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

gconnect(Request):-
	%I need to get the code from the request
	http_parameters(Request,[code(Code,[default(default)])]),
	DictOut = _A{access_token:test, token_type:hello, code:Code},
	read_client_secrets(_MyWeb,Client_Id,Client_Secret),
	post_to_google(Reply,Code,Client_Id,Client_Secret),
	reply_json(DictOut).


call_back_script -->
	js_script({|javascript||
		      console.log("script runs");
		      function signInCallback(authResult) {
                        console.log("got to call back");
                        if (authResult['code']) {
                         console.log("has code");
                         console.log(authResult['code']);
			 $('#signInButton').attr('style','display: none');

			 $.post("/gconnect",
			   {code:authResult['code']},
			   function(data,status){
			    console.log("Data: " + data.access_token + "\nToken type" + data.token_type + "\nStatus: " + status);
			   });
			 /*
			 $.ajax({
			       type: 'POST',
			       url: '/gconnect',
			       processData:false,
			       //contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
			       contentType: 'application/octet-stream; charset=utf-8',
			       data: {code:authResult['code']},
			       success: function(result){
					    console.log("succes");
					    console.log(result);
					}
			   });
                          */

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


