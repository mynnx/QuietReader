package QuietReader::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

QuietReader::Schema::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 otp

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 last_accessed

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "otp",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "last_accessed",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("username");
__PACKAGE__->add_unique_constraint("id", ["id"]);

=head1 RELATIONS

=head2 feeds

Type: has_many

Related object: L<QuietReader::Schema::Result::Feed>

=cut

__PACKAGE__->has_many(
  "feeds",
  "QuietReader::Schema::Result::Feed",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-01 00:40:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1dtrjmY0ZscC9azALznWlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
