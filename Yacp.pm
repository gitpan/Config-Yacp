package Config::Yacp;
use strict;
use Parse::RecDescent;
use vars qw ($VERSION $grammar);
use Carp;

$VERSION='1.00';

$grammar = q(
	file: section(s)
	  {
	    my %file;
	    foreach(@{$item[1]}){
	      $file{$_->[0]} = $_->[1];
	    }
	    \%file;
	  }
	section: header assign(s)
	  {
	    my %sec;
	    foreach(@{$item[2]}){
	      $sec{$_->[0]} = $_->[1];
	    }
	    [ $item[1], \%sec ]
	  }
	header: '[' /\w+/ ']' { $item[2] }
	assign: /\w+/ '=' /\w+/ { [$item[1], $item[3]] }
	);

sub new{
  my($self,$file)=@_;
  my $parser = Parse::RecDescent->new($grammar);

  my $ini;
  {
    $/ = undef;
    open(FILE,"$file")||croak"Can't open $file: $!";
    $ini = <FILE>;
    close FILE; 
  }

  bless my $tree = $parser->file($ini);
  return $tree;
}

sub get_sections{
  my $self=shift;
  my @sections = sort keys %$self;
  return @sections;
}

sub get_parameters{
  my($self,$section)= @_;
  croak"No section given" if !defined $section;
  croak"Invalid section" if !exists $$self{$section};
  my @parameters = sort keys %{$$self{$section}};
  return @parameters;
}

sub get_value{
  my($self,$section,$parameter)=@_;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Invalid section argument" if !exists $$self{$section};
  croak"Invalid parameter argument" if !exists $$self{$section}{$parameter};
  my $value = $$self{$section}{$parameter};
  return $value;
}

sub write{
  my $self=shift;
  croak"This function is not yet implemented.";
}

sub dmp{
  require Data::Dumper;
  my $self=shift;
  print Data::Dumper::Dumper($self);
}
1;
__END__

=head1 NAME

Config::Yacp - Yet Another Configuration file Parser

=head1 SYNOPSIS 

use Config::Yacp;

my $cfg=Config::Yacp->new("config.ini");

# Get the names of the sections
my @sections=$cfg->get_sections;

# Get the parameter names within a section
my @params = $cfg->get_parameters("Section1");

# Get the value of a specific parameter within a section
my $value = $cfg->get_value("Section1","Parameter1");

=head1 DESCRIPTION

=over 5

=item new

C<< my $cfg=Config::Yacp->new("config.ini"); >>

This constructor returns a reference to a hash. It uses Parse::RecDescent and a simple grammar to parse out the ini file, and put it into a hash. The ini files are similar to those used by Windows, i.e. section names are surrounded by [] and the parameter/values are separated by an = sign.

=item get_sections

C<< my @sections = $cfg->get_sections; >>

This method retrieves the section names in a list format

=item get_parameters

C<< my @params = $cfg->get_parameters("Section1"); >>

This method retrieves the parameter names for a given section and returns them in a list format. This method will croak if a section name is not passed to it or if the section name given to it does not exist.

=item get_value

C<< my $value = $cfg->get_value("Section1","Parameter1"); >>

This method retrieves the value of the section and parameter that are passed to it. It will croak if either the section name or parameter name does not exist, or if there aren't enough arguments passed to it.

=back

=head1 EXPORT

None by default

=head1 ACKNOWLEDGEMENTS

I got the idea for this from the book "Data Munging with Perl", written by Dave Cross.

=head1 AUTHOR

Thomas J. Stanley Jr.

Thomas_J_Stanley@msn.com

I can also be found at http://www.perlmonks.org as TStanley. You can also direct any questions concerning this module there

=head1 COPYRIGHT

=begin text

Copyright (C)2003 Thomas Stanley. All rights reserved. This program is free software; you can distribute it and/or modify it under the same terms as Perl itself.

=end text

=begin html

Copyright E<copy> 2003 Thomas Stanley. All rights reserved. This program is free software; you can distribute it and/or modify it under the same terms as Perl itself.

=end html

=head1 SEE ALSO

perl

Parse::RecDescent

=cut

