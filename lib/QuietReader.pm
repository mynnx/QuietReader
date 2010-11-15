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

sub build_feeds {
	my $reader = shift;
	my $categories = { none => [] };
	foreach my $feed ($reader->feeds) {
		my $feed_details = { 
			title => $feed->title, 
			href => (split '/', $feed->id, 2)[-1]
		};
		my @feed_categories = @{$feed->categories};
		if (! @feed_categories) {
			push @{$categories->{'none'}}, $feed_details;
		} else {
			foreach my $category (@feed_categories) {
				my $label = $category->label;
				if (! $categories->{$label}) {
					$categories->{$label} = [ $feed_details ];
				} else {
					push @{$categories->{$label}}, $feed_details;
				}
			}
		}
	}
	return $categories;
}

sub render_tags {
	my $reader = make_reader(session('user'), session('pass'));
	my $error = $reader->error ? "error: " . $reader->error : "";
	my $tagged = build_feeds($reader);
	my $untagged = delete $tagged->{'none'} || ();
	debug Dumper $untagged;
    template tags => {
		tagged => $tagged,
		untagged => $untagged,
		error => $error
    };
};

get '/' => \&render_tags;
get '/tags' => \&render_tags;

get '/login' => sub {  
	my $path_requested = vars->{requested_path} || '/';
	my $failed = params->{failed};
	template login => {
		path_requested => $path_requested,
		login_failed => $failed ? "Login failed" : "",
	};
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
