
=head1 NAME

Slaughter::Transport::mojo - HTTP transport class.

=head1 SYNOPSIS

This transport copes with fetching files and policies from a remote server
using HTTP or HTTPS as a transport.

=cut

=head1 DESCRIPTION

This transport is slightly different to the others, as each file is fetched
on-demand, with no local filesystem access and no caching.

If HTTP Basic-Auth is required the appropriate details should be passed to
slaughter with the "C<--username>" & "C<--password>" flags.

=cut



use strict;
use warnings;



package Slaughter::Transport::mojo;


#
# The version of our release.
#
our $VERSION = "3.0.4";



=head2 new

Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    #
    # Explicitly ensure we have no error.
    #
    $self->{ 'error' } = undef;

    bless( $self, $class );
    return $self;
}



=head2 name

Return the name of this transport.

=cut

sub name
{
    return ("mojo");
}



=head2 isAvailable

Return whether this transport is available.

As we're pure-perl it should be always available if the C<Mojo::UserAgent> module is
present.

=cut

sub isAvailable
{
    my ($self) = (@_);

    my $mojo = "use Mojo::UserAgent;";

    ## no critic (Eval)
    eval($mojo);
    ## use critic

    if ($@)
    {
        $self->{ 'error' } = "Mojo::UserAgent module not available.";
        return 0;
    }

    #
    # Module loading succeeded; we're available.
    #
    return 1;
}



=head2 error

Return the last error from the transport.

This is only set in L</isAvailable>.

=cut

sub error
{
    my ($self) = (@_);
    return ( $self->{ 'error' } );
}



=head2 fetchContents

Fetch the contents of a remote URL, using HTTP basic-auth if we should

=cut

sub fetchContents
{
    my ( $self, %args ) = (@_);


    #
    #  The file to fetch, and the prefix from which to load it.
    #
    my $pref = $args{ 'prefix' };
    my $url  = $args{ 'file' };

    #
    #  Is this fully-qualified?
    #
    if ( $url !~ /^http/i )
    {
        $url = "$self->{'prefix'}/$pref/$url";

        $self->{ 'verbose' } &&
          print "\tExpanded to: $url  \n";
    }

    my $ua = Mojo::UserAgent->new;

    #
    # Use a proxy, if we should.
    #
    $ua = $ua->detect_proxy;

    #
    #  Make a request, do it in this fashion so we can use Basic-Auth if we need to.
    #
    if ( $self->{ 'username' } && $self->{ 'password' } )
    {
        my ( $schema, $hostpath ) = split( '//', $url, 2 );
        $url =
          $schema . '//' . $self->{ 'username' } . ':' . $self->{ 'password' } .
          '@' . $hostpath;
    }

    #
    #  Send the request
    #
    #print "url: " . $url . "\n";
    my $tx = $ua->build_tx( GET => $url );
    $ua->start($tx);
    if ( my $res = $tx->success )
    {
        $self->{ 'verbose' } &&
          print "\tOK\n";
        return ( $res->body );
    }

    #
    #  Failed?
    #
    my ( $err, $code ) = $tx->error;
    $self->{ 'verbose' } &&
      print $code ? "\tFailed to fetch: $url - $code response: $err\n" :
                    "Connection error: $err\n";

    #
    #  Return undef, but hide this from perlcritic.
    #
    my $res = undef;
    return ($res);

}


1;


=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 LICENSE

Copyright (c) 2010-2014 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
