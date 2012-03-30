#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $filename = $ARGV[0];
my $var = "/Users/cjg/Projects/InsideTheBox/var";
`rm -rf $var/*`;

my $types = {};
my $resource_types = {};
my $type_resources = {};
my $data = new InsideTheBox::Dataset( $filename );
$data->map( sub { my( $t ) = @_;
	return unless( $t->{p} eq "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" );
	$resource_types->{$t->{s}}->{$t->{o}}=1;
	$type_resources->{$t->{o}}->{$t->{s}}=1;
	$types->{$t->{o}}++;
});
foreach my $type ( sort { $types->{$b}<=>$types->{$a} } keys %{$types} )
{
	print "\n";
	print "\n";
	print "==================================================\n";
	print "\n";
	print "$type -> ".$types->{$type}."\n";
	my $other_types = {};
		foreach my $resource ( keys %{$type_resources->{$type}} )
		{
			OT: foreach my $other_type ( keys %{$resource_types->{$resource}} )
			{
				next OT if $type eq $other_type;
				$other_types->{$other_type}++;
			}
		}
	if( scalar keys %{$other_types} )
	{
		print "CO-CLASSES:\n";
		foreach my $other_type ( sort { $other_types->{$b}<=>$other_types->{$a} } keys %{$other_types} )
		{
			print sprintf( "% 5d - % 3d%% %s\n", $other_types->{$other_type}, 100*$other_types->{$other_type}/$types->{$type} , $other_type );
		}
	}
	else
	{
		print "NO CO-CLASSES.\n";
	}
}

#print Dumper( $types );
#print Dumper( $resource_types );
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

