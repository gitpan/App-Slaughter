#!/usr/bin/perl -Ilib/
#
# A simple test that ensures that the code that is included in some
# modules, as inline examples, is actually correct.
#
# Shamelessly inspired by Text::Synopsis.
#
# Steve
# --


use strict;
use warnings;

use File::Find;
use Test::More qw! no_plan !;

#
# Count of modules we've found.
#
my $count = 0;

#
# Shared variables as required to avoid missing declerations.
#
our ( $package, $hostname, $fqdn );


#
#  Find our examples and test them.
#
find( { wanted => \&checkExamples, no_chdir => 1 }, '.' );



#
# Find *.pm and test the example sections of any that are present.
#
sub checkExamples
{

    # The file.
    my $file = $File::Find::name;

    # We don't care about directories
    return if ( !-f $file );

    # Nor about non-modules.
    return unless ( $file =~ /\.pm$/ );

    # Nor about our transports or packages
    return if ( $file =~ /(Transport|Packages|modules)/i );

    #
    # Open the file.
    #
    open( my $handle, "<", $file ) or
      die "Failed to open $file - $!";

    #
    # Helper for whether we're inside an example or not - note we only
    # check the first example.
    #
    my $in_ex = 0;
    my $example;

    while ( my $line = <$handle> )
    {
        #
        #  Start of example?
        #
        if ( ( $line =~ /for example begin/ ) && ( !$example ) )
        {
            $in_ex = 1;
        }
        elsif ( $line =~ /for example end/ )
        {
            #
            #  End of example.
            #
            $in_ex = 0;
        }
        else
        {
            #
            #  Store the body of any example we're inside.
            #
            if ($in_ex)
            {
                $example .= $line;
            }
        }
    }
    close($handle);

    #
    #  See if we got some code
    #
    ok( $example && length($example) > 0,
        "Our module file has some example code: $file" );

    #
    #  If we did then eval the thing, inside a subroutine with a unique
    # name, to test for validity.
    #
    if ($example)
    {
        my $code = "sub sub_$count(){ $example ; } ";

        eval $code;
        ok( !$@, "No errors compiling that example code." );

        $count += 1;
    }
}
