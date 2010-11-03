#!/usr/bin/perl

use WebService::Google::Reader;
use Data::Dumper;

my $user = 'themynnx';
my $pass = 'mxyznanqx';

my $reader = WebService::Google::Reader->new(
	username => $user,
	password => $pass,
	debug => 1,
);

my $foo = $reader->mark_read_tag(('noisy'));
print Dumper $foo;
