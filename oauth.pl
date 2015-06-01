

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
:- use_module(library(http/http_ssl_plugin)).

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
             %'http://requestb.in/10qo0si1',
	     'https://www.googleapis.com/oauth2/v3/token',
		form([
		  code=Code,
		  client_id=Client_Id,
                  client_secret=Client_Secret,
		  redirect_uri='http://localhost:5000/',
		  grant_type=Grant_type
	      ]),
              Reply,
             [cert_verify_hook(cert_verify)]
          ).
   %term_to_atom(Term,Reply).

post_to_google2(JSon,Code,CID,CS):-
	Base ='https://www.googleapis.com/oauth2/v3/token',
	ListofData=[
		       code=Code,
		       client_id=CID,
		       client_secret=CS,
		       redirect_uri='http://localhost:5000/',
		       grant_type=authorization_code

			  ],
	http_open(Base, In,
                  [ cert_verify_hook(cert_accept_any),
		    method(post),post(form(ListofData))
                  ]),
	json_read(In,JSon),
	close(In).


post_to_google3(Profile,Code,CID,CS):-
	Base ='https://www.googleapis.com/oauth2/v3/token',
	ListofData=[
		       code=Code,
		       client_id=CID,
		       client_secret=CS,
		       redirect_uri='http://localhost:5000/',
		       grant_type=authorization_code

			  ],
        http_open(Base, In,
                  [ cert_verify_hook(cert_verify),
		    method(post),post(form(ListofData))
                  ]),
	call_cleanup(json_read_dict(In, Profile),
		     close(In)).


cert_verify(_SSL, _ProblemCert, _AllCerts, _FirstCert, _Error) :-
        debug(ssl(cert_verify),'~s', ['Accepting certificate']).



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
	trace,
	post_to_google3(Reply,Code,Client_Id,Client_Secret),
	reply_json(_{reply:Reply}).


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
			    //console.log("Data: " + data.reply + "\nStatus: " + status);
			    console.log("Access Token: " + data.access_token + "\nExpires in : " + data.expires_in + "\nToken_type : " + data.token_type +  "\nStatus: " + status);
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


