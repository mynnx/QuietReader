package QuietReader;
use Dancer ':syntax';
use Data::Dumper;
use Dancer::Session;
use WebService::Google::Reader;

sub make_reader {
	my ($user, $pass) = @_;
	my $reader = WebService::Google::Reader->new(
		username => $user,
		password => $pass,
		debug => 0,
	);
	return $reader;
}

before sub {
	if (! session('user') && request->path_info !~ m{^/login}) {
		var requested_path => request->path_info;
		request->path_info('/login');
	}
};

sub render_feeds {
	my $reader = make_reader(session('user'), session('pass'));
	my $rv = "";
	my @tags = $reader->tags;
	foreach my $tag (@tags) {
		my $id = $tag->id;
		my $name = $id;
		$name =~ s|.+/.+/label/(.+)|$1|;
		$name =~ s|.+/.+/state/.+/(.+)|$1|;
		$rv .= $name . '<br>';
	}
	return $rv;
};

get '/' => \&render_feeds;
get '/feeds' => \&render_feeds;

get '/login' => sub { 
	my $path_requested = vars->{requested_path} || '/';
	my $rv = qq!
	<form action="/login" method="POST">
		<input type="text" name="username" /><br>
		<input type="password" name="password" /><br>
		<input type="hidden" name="path" value="$path_requested" />
		<input type="submit" value="Log in" />
	</form>!;
	debug "LOGIN";
	$rv .= "Error authenticating!" if params->{failed};
	return $rv;
};

post '/login' => sub {
	my $user = params->{username};
	my $pass = params->{password};
	my $rv = "";
	my $reader = make_reader($user, $pass);

	# Call ->tags, which may actually cause an ->error; creating a new 
	# 	::Reader doesn't actually hit the API, I don't think.
	my @tags = $reader->tags;
	if ($reader->error) {
		redirect '/login?failed=1';
	} else {
		session user => $user,
		session pass => $pass,
		# TODO generate/store OTP, encrypt password with it and put in cookie
		# - clear your session persistent store; passwords are plaintext for now!
		redirect params->{path} || '/';
	}
	return $rv;
};



true;
