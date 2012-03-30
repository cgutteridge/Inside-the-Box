#!/usr/bin/perl

use strict;
use warnings;

my $filename = "/Users/cjg/Projects/InsideTheBox/data.nt";
my $var = "/Users/cjg/Projects/InsideTheBox/var";
`rm -rf $var/*`;

my $data = new InsideTheBox::Dataset( $filename );
$data->map( sub { my( $t ) = @_;
	return unless( $t->{p} eq "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" );
	print $t->{o}."\n";
});
exit;

package InsideTheBox::Dataset;

use strict;
use Data::Dumper;

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
	my $uri_re = "(<([^>]*)>|(_:[^\\s]+))";

	open( my $fh, '<:utf8', $self->{filename} ) || die "Could not open ".$self->{filename}.": $!";
	while( my $line = readline($fh) )
	{
		# may break on \" in literals
		my $t = bless {}, "InsideTheBox::Triple";
		#               1-3       4-6       7 8-10    11      12   13-15    16
		if( $line =~ m/^$uri_re\s+$uri_re\s+($uri_re|"([^"]*)"(\^\^$uri_re|@([a-zA-Z-]+))?)\s+\./ )
		{
			if( defined $2 ) { $t->{s} = $2; $t->{s_type} = 'resource'; }
			if( defined $3 ) { $t->{s} = $3; $t->{s_type} = 'bnode'; }

			if( defined $5 ) { $t->{p} = $5; $t->{p_type} = 'resource'; }
			if( defined $6 ) { $t->{p} = $6; $t->{p_type} = 'bnode'; }

			if( defined $9 ) { $t->{o} = $9; $t->{o_type} = 'resource'; }
			if( defined $10 ) { $t->{o} = $10; $t->{o_type} = 'bnode'; }

			if( defined $11 ) { $t->{o} = $11; $t->{o_type} = 'literal'; }

			if( defined $14 ) { $t->{o_datatype} = $14; } # don't record bnode datatypes?
			if( defined $15 ) { $t->{o_datatype} = $15; } # don't record bnode datatypes?

			if( defined $16 ) { $t->{o_lang} = $16; } 
		}
		else
		{
#			print "FAIL: $line\n";
			next;
		}
		&{$func}( $t );
	}
} 
package InsideTheBox::Triple;

use strict;

