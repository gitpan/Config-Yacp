package Config::Yacp;
use strict;
use Parse::RecDescent;
use Carp;
use Fcntl qw /:flock/;
use vars qw ($VERSION $grammar);

$VERSION='1.1';

$grammar = q(
	file: section(s)
	  {
	    my %file;
	    foreach(@{$item[1]}){
	      $file{$_->[0]} = $_->[1];
	    }
	    \%file;
	  }
	section: header assign(s?)
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
    flock(FILE,LOCK_SH) or die"Unable to obtain a file lock: $!\n";
    $ini = <FILE>;
    flock(FILE,LOCK_UN);
    close FILE; 
  }

  bless my $tree = $parser->file($ini);
  $$tree{INI}=$file;
  return $tree;
}

sub get_sections{
  my $self=shift;
  my @returned;
  my @sections = sort keys %$self;
  foreach(@sections){ push @returned,$_ unless $_ eq "INI"; }
  return @returned;
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

sub add_section{
  my ($self,$section)=@_;
  croak"Missing arguments" if scalar @_ < 2;
  croak"Section exists!" if exists $$self{$section};
  $$self{$section}="";  
}

sub add_parameter{
  my ($self,$section,$para,$value)=@_;
  croak"Missing arguments" if scalar @_ < 4;
  croak"Can't add to internal parameter" if $section=~/^INI$/i;
  croak"Non-Existent section" if !exists $$self{$section};
  croak"Parameter exists" if exists $$self{$section}{$para};
  $$self{$section}{$para}=$value; 
}

sub del_section{
  my ($self,$section)=@_;
  croak"Missing arguments" if scalar @_ < 2;
  croak"Internal variable can't be deleted" if $section eq "INI";
  croak"Non-Existent section" if !exists $$self{$section};
  delete $$self{$section};
}

sub del_parameter{
  my ($self,$section,$para)=@_;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Non-Existent section" if !exists $$self{$section};
  croak"Non-Existent parameter" if !exists $$self{$section}{$para};
  delete $$self{$section}{$para};
}

sub set_value{
  my ($self,$section,$para,$value)=@_;
  croak"Non-Existent section" if !exists $$self{$section};
  croak"Non-Existent parameter" if !exists $$self{$section}{$para};
  $$self{$section}{$para}=$value;
}

sub get_ini{
  my $self=shift;
  return $$self{INI};
}

sub save_ini{
  my $self=shift;
  my $file=$self->get_ini;
  open FH,">$file"||die"Unable to open $file: $!\n";
  flock(FH,LOCK_EX) or die "Unable to obtain file lock: $!\n";
  foreach my $section(sort keys %{$self}){
    print FH "[$section]\n" unless $section eq "INI";
    foreach my $para(sort keys %{$$self{$section}}){
      print FH "$para = $$self{$section}{$para}\n";
    }
    print FH "\n" unless $section eq "INI";
  }
  flock(FH,LOCK_UN);
  close FH;
  $self=$self->new($file);
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

# Add a section
$cfg->add_section("Section3");

# Add a parameter and value to a section
$cfg->add_parameter("Section3","Key5","Value5");

# Change the value of a parameter within a section
$cfg->set_value("Section3","Key5","Value99");

# Delete a parameter and value in a section
$cfg->del_parameter("Section1","key1");

# Delete an entire section
$cfg->del_section("Section2");

# Save the changes to the .ini file
$cfg->save_ini;

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

=item add_section

C<< $cfg->add_section("Section3"); >>

This method will add a section into the object, but will not exist in the .ini file until the save_ini method is called. This method will croak if the section being added already exists within the object.

=item add_parameter

C<< $cfg->add_parameter("Section3","key5","value5"); >>

This method will add a parameter and value to a specific section within the object. The parameter will exist only within the object until the save_ini method is called. This method will croak if it is passed an invalid section name, or the parameter exists within the section.

=item set_value

C<< $cfg->set_value("Section3","key5","value9"); >>

This method will change the value of the specified section/parameter within the object, and will write the change to the .ini file upon callinig the save_ini method. This method will croak if either the section or parameter name does not exist.

=item del_parameter

C<< $cfg->del_parameter("Section3","key5"); >>

This method will delete the specified parameter within a section. The change will occur within the object and is written out to the .ini file upon calling the save_ini method. This method will croak if either the section or parameter name is non-existent.

=item del_section

C<< $cfg->del_section("Section3"); >>

This method will delete the specified section inside the object. It will also remove any parameters that were under that section heading. This method will croak if the section does not exist.

=item save_ini

C<< $cfg->save_ini; >>

This method will save the parameters that have been changed inside the object back to the .ini file that was specified when the object was created. It will then re-read the .ini file and return an updated reference.

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

