#!/usr/bin/perl -w

use strict;

package HTMLLinkExtractor;

use vars qw(@ISA);

@ISA = qw(HTML::Parser);

require HTML::Parser;

use strict;


sub trimwhitespace($);

my $parser = new HTMLLinkExtractor;

$parser->parse_file(\*STDIN);

my $link;
foreach $link (@{$parser->{URLArray}}){
  	print STDOUT "$link->{href}\t" 	if (defined $link->{href});
	print STDOUT trimwhitespace($link->{text}) if (defined $link->{text});
	print STDOUT "\t";
	print STDOUT $link->{shortcuturl} if (defined( $link->{shortcuturl}));
	print STDOUT "\t";
	print STDOUT $link->{imageurl} if (defined( $link->{imageurl}));
  	print STDOUT "\n";
   }

sub start
{
	my($self,$tag,$attr,$attrseq,$orig) = @_;
	
	if ( $tag eq 'a'){
			$self->{thisLink} = $attr;
			push(@{$self->{URLArray}},	$self->{thisLink} );
			$self->{got_href}++;
		}
	if ( $tag eq 'img'){
		$self->{thisLink}{imageurl}= $attr->{src}; 
	}
}

sub end
{
	my ($self,$tag) = @_;
	$self->{got_href}-- if ($tag eq 'a' && $self->{got_href} )
}

sub text
{
	my ($self,$text ) = @_;
	
	if ($self->{got_href} )
    {
		$self->{thisLink}{text}.= $text; 
	 }
}

# Remove whitespace from the start and end of the string
sub trimwhitespace($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
