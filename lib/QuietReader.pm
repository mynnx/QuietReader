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

get '/' => sub { template 'login' };

post '/tags' => sub {
	session user => params->{username};
	session pass => params->{password};
	my $user = session->{user};
	my $pass = session->{pass};

	debug "About to log in as $user with password $pass";
	my $reader = make_reader($user, $pass);
	debug "error: " . $reader->error if $reader->error;

    template tags => {
        names => [ map { (split '/', $_->id)[-1] } $reader->tags ]
    };
};

true;
