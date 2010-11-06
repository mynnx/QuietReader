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

get '/' => sub { qq!
	<form action="/tags" method="POST">
		<input type="text" name="username" /><br>
		<input type="password" name="password" /><br>
		<input type="submit" value="Log in" />
	</form>!;
};

post '/tags' => sub {
	session user => params->{username};
	session pass => params->{password};
	my $user = session->{user};
	my $pass = session->{pass};
	my $rv = "";
	my $reader = make_reader($user, $pass);
	debug "About to log in as $user with password $pass";
	debug "error: ${reader->error}" if $reader->error;

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

true;
