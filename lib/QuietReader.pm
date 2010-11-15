package QuietReader;
use Dancer ':syntax';
use Dancer::Session;
use Dancer::Plugin::DBIC;

use WebService::Google::Reader;
use Data::Dumper;
use Data::Random qw(rand_chars);
use Crypt::OTP qw(OTP);

sub make_reader_otp {
	my ($user, $otp_pass) = @_;
	my $auth = schema->resultset('Auth')->find({ username => $user });
	return undef if ! $auth;

	my $pass = OTP($auth->otp, $otp_pass, 1);
	return make_reader($user, $pass);
}

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

# Gets a list of all feeds and the categories they belong
# to, and organizes them by category.  Returns a hashref like:
# {
# 	'blogs' => [{ title => 'a blog', href => 'http://...'}, ...] }
# }
# 
# Feeds not under any category are put in the 'none' key.
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
	my $reader = make_reader_otp(session('user'), session('otp_pass'));

	if (! $reader || $reader->error) {
		my $error = "error: ";
		if ($reader) {
			$error .= $reader->error;
		} else {
			$error = "Could not retrieve OTP from database";
		}
		session error => $error;
		redirect '/login';
	} else {
		my $tagged = build_feeds($reader);
		my $untagged = delete $tagged->{'none'} || [];
		template tags => {
			tagged => $tagged,
			untagged => $untagged,
		};
	}
};

get '/' => \&render_tags;
get '/tags' => \&render_tags;

get '/login' => sub {  
	my $path_requested = vars->{requested_path} || '/';
	template login => {
		path_requested => $path_requested,
		error => session('error')
	};
};

post '/login' => sub {
	my $user = params->{username};
	my $pass = params->{password};
	my $reader = make_reader($user, $pass);

	# Call ->tags, which may actually cause an ->error; creating a new 
	# 	::Reader doesn't actually hit the API, I don't think.
	my @tags = $reader->tags;
	if ($reader->error) {
		session error => 'Login failed.  Check your credentials, bro.';
		redirect '/login';
	} else {
		# OTP generation uses Crypt::Random, which isn't recommended -
		# 	find a different way to make a OTP if you're paranoid.
		my $otp = join('', rand_chars(set => 'all', size => length $pass));
		my $otp_pass = OTP($otp, $pass, 1);
		session user => $user;
		session otp_pass => $otp_pass;
		
		my $auth = schema->resultset('Auth')->update_or_create({
			username => $user,
			otp => $otp
		});

		redirect params->{path} || '/';
	}
};

true;
