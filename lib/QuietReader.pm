package QuietReader;
use Dancer ':syntax';
use Dancer::Session;
use WebService::Google::Reader;

sub make_reader {
	my ($user, $pass) = $@;
	my $reader = WebService::Google::Reader->new(
		username => $user,
		password => $pass,
		#debug => 1,
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
	debug "About to log in as $user with password $pass";

	my $reader = make_reader($user, $pass);
	debug "error: ${reader->error}" if $reader->error;
	my $tags = $reader->tags;
	debug "tags fetched: $tags";
	my $rv = "";
	foreach my $tag (@$tags) {
		$rv += $tag->id if $tag;
	}
	mark_tags_read(('noisy'));
	return $rv;
};

true;
