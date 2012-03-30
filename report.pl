#!/usr/bin/perl

use strict;
use warnings;

my $filename = "/Users/cjg/Projects/InsideTheBox/data.nt";

my $data = new InsideTheBox::Dataset( $filename );
$data->map( sub { my( $t ) = @_;
	print $t->o."\n";
});
exit;

package InsideTheBox::Dataset;

use strict;

sub new
{
	my( $class, $filename ) = @_;

	if( !-e $filename )
	{
		print STDERR "Failed to read $filename\n";
		return;
	}

	my $self = bless { filename=>$filename }, $class;

	return $self;
}

sub map
{
	my( $self, $func ) = @_;

	open( my $fh, '<:utf8', $self->{filename} ) || die "Could not open ".$self->{filename}.": $!";
	while( my $line = readline($fh) )
	{
		print $line;
	}
}
package InsideTheBox::Triple;

use strict;

