package CGI::Session::Driver::mysql;

# $Id$

use strict;
#use diagnostics;

use Carp;
use CGI::Session::Driver::DBI;

@CGI::Session::Driver::mysql::ISA       = qw( CGI::Session::Driver::DBI );
$CGI::Session::Driver::mysql::VERSION   = "2.01";


sub _mk_dsnstr {
    my ($class, $dsn) = @_;
    unless ( $class && $dsn && ref($dsn) && (ref($dsn) eq 'HASH')) {
        croak "_mk_dsnstr(): usage error";
    }

    my $dsnstr = $dsn->{DataSource};
    if ( $dsn->{Socket} ) {
        $dsnstr .= sprintf(";mysql_socket=%s", $dsn->{Socket});
    }
    if ( $dsn->{Host} ) {
        $dsnstr .= sprintf(";host=%s", $dsn->{Host});
    }
    if ( $dsn->{Port} ) {
        $dsnstr .= sprintf(";port=%s", $dsn->{Port});
    }

    return $dsnstr;
}


sub init {
    my $self = shift;
    if ( $self->{DataSource} && ($self->{DataSource} !~ /^dbi:mysql/i) ) {
        $self->{DataSource} = "dbi:mysql:database=" . $self->{DataSource};
    }

    if ( $self->{Socket} && $self->{DataSource} ) {
        $self->{DataSource} .= ';mysql_socket=' . $self->{Socket};
    }
    return $self->SUPER::init();
}

sub store {
    my $self = shift;
    my ($sid, $datastr) = @_;
    croak "store(): usage error" unless $sid && $datastr;

    my $dbh = $self->{Handle};
    $dbh->do("REPLACE INTO " . $self->table_name . " (id, a_session) VALUES(?, ?)", undef, $sid, $datastr)
        or return $self->set_error( "store(): \$dbh->do failed " . $dbh->errstr );
    return 1;
}

# If the table name hasn't been defined yet, check this location for 3.x compatibility
sub table_name {
    my $self = shift;
    unless (defined $self->{TableName}) {
        $self->{TableName} = $CGI::Session::MySQL::TABLE_NAME;
    }
    return  $self->SUPER::table_name(@_);
}

1;

__END__;

=pod

=head1 NAME

CGI::Session::Driver::mysql - CGI::Session driver for MySQL database

=head1 SYNOPSIS

    $s = new CGI::Session( "driver:mysql", $sid);
    $s = new CGI::Session( "driver:mysql", $sid, { DataSource  => 'dbi:mysql:test',
                                                   User        => 'sherzodr',
                                                   Password    => 'hello' });
    $s = new CGI::Session( "driver:mysql", $sid, { Handle => $dbh } );

=head1 DESCRIPTION

B<mysql> stores session records in a MySQL table. For details see L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>, its parent class.

=head2 DRIVER ARGUMENTS

B<mysql> driver supports all the arguments documented in CGI::Session::Driver::DBI. In addition, I<DataSource> argument can optionally leave leading "dbi:mysql:" string out:

    $s = new CGI::Session( "driver:mysql", $sid, {DataSource=>'shopping_cart'});
    # is the same as:
    $s = new CGI::Session( "driver:mysql", $sid, {DataSource=>'dbi:mysql:shopping_cart'});

=head2 BACKWARDS COMPATIBILITY

For backwards compatibility, you can also set the table like this before
calling C<new()>. However, it is not recommended because it can cause conflicts
in a persistent environment. 

 $CGI::Session::MySQL::TABLE_NAME = 'my_sessions';

=head1 LICENSING

For support and licensing see L<CGI::Session|CGI::Session>.

=cut
