package Config::Yacp;
use strict;
use Parse::RecDescent;
use Carp;
use Fcntl qw /:flock/;
use vars qw ($VERSION $grammar);
$VERSION='1.181';

BEGIN{ $::RD_AUTOACTION=q{ [@item[1..$#item]] }; }

# Set the grammar
$grammar = q(
	file:    section(s)
        section: header pair(s?)
	header:  /\[(\w+)\]/ { $1 } 
	pair:    /(\w+)\s?=\s?(\w+)?(\s+[;#][\s\w]+)?\n/
	  {
	    if(!defined $3){
	      [$1,$2];
	    }else{
	      [$1,$2,$3];
	    }
	  }
	);

sub new{
  my($self,$file,$cm)=@_;

  if(!defined $cm){
    $cm="#";
  }elsif($cm!~/[#;]/){
    croak"Invalid comment marker";
  }

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
  
  my $tree = $parser->file($ini);
  my $Config = deparse($tree);
  bless $Config,$self;
  $Config->{INI}=$file;
  $Config->{CM}=$cm;
  return $Config;
}

sub get_sections{
  my $self=shift;
  my @returned;
  my @sections = sort keys %$self;
  foreach(@sections){ push @returned,$_ unless $_ eq "INI" or $_ eq "CM"; }
  return @returned;
}

sub get_parameters{
  my($self,$section)= @_;
  croak"No section given" if !defined $section;
  croak"Invalid section" if !exists $self->{$section};
  carp"Can't Retrieve Internal Parameters" if $section=~/^(INI|CM)$/;
  my @parameters = sort keys %{$self->{$section}};
  return @parameters;
}

sub get_value{
  my($self,$section,$parameter)=@_;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$parameter};
  my $value = $self->{$section}->{$parameter}->[0];
  return $value;
}

sub get_comment{
  my($self,$section,$parameter)=@_;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Invalid section argument" if !exists $self->{$section};
  croak"Invalid parameter argument" if !exists $self->{$section}->{$parameter};
  if (!defined $self->{$section}->{$parameter}->[1]){
    local $SIG{__WARN__}=sub{ $@=shift; };
    carp"No comment available for this parameter";
  }else{
    my $comment=$self->{$section}->{$parameter}->[1];
 
    return $comment;
  }
}

sub get_marker{
  my $self=shift;
  return $self->{CM};
} 

sub add_section{
  my ($self,$section)=@_;
  croak"Missing arguments" if scalar @_ < 2;
  croak"Section exists!" if exists $self->{$section};
  $self->{$section}="";  
}

sub add_parameter{
  my ($self,$section,$para,$value,$comment)=@_;
  croak"Missing arguments" if scalar @_ < 4;
  croak"Can't add to internal parameter" if $section=~/^INI|CM$/i;
  if(!exists $self->{$section}){
    $self->add_section($section);
  }
  croak"Parameter exists" if exists $self->{$section}->{$para};
  $self->{$section}->{$para}=[$value];
  if(defined $comment){ push @{$self->{$section}->{$para}},$comment; } 
}

sub add_comment{
  my ($self,$section,$para,$comment)=@_;
  croak"Missing arguments" if scalar @_ < 4;
  croak"Can't add to internal parameter" if $section=~/^INI|CM$/i;
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$para};
  if(defined $self->{$section}{$para}[1]){
    $self->set_comment($section,$para,$comment);
  }else{
    push @{$self->{$section}->{$para}},$comment;
  }
}
 
sub del_section{
  my ($self,$section)=@_;
  croak"Missing arguments" if scalar @_ < 2;
  croak"Internal Parameter Can't Be Deleted" if $section=~/^INI|CM$/i;
  croak"Non-Existent section" if !exists $self->{$section};
  delete $self->{$section};
}

sub del_parameter{
  my ($self,$section,$para)=@_;
  croak"Internal variable can't be deleted" if $section=~/^INI|CM$/i;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$para};
  delete $self->{$section}->{$para};
}

sub del_comment{
  my ($self,$section,$para)=@_;
  carp"Internal variable does not have comments to delete" if $section=~/^INI|CM$/i;
  croak"Missing arguments" if scalar @_ < 3;
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$para};
  if(defined $self->{$section}->{$para}->[1]){
    pop @{$self->{$section}->{$para}};
  }else{
    local $SIG{__WARN__}=sub{ $@=shift; };
    carp"No comment located for that parameter";
  }
}
 
sub set_value{
  my ($self,$section,$para,$value)=@_;
  croak"Can't Change Internal Parameter" if $section=~/^(INI|CM)$/;
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$para};
  $self->{$section}->{$para}->[0]=$value;
}

sub set_comment{
  my ($self,$section,$para,$comment)=@_;
  croak"Cannot set comments for internal parameters" if $section=~/^INI|CM$/i;
  croak"Missing arguments" if scalar @_ < 4; 
  croak"Non-Existent section" if !exists $self->{$section};
  croak"Non-Existent parameter" if !exists $self->{$section}->{$para};
  if(!defined $self->{$section}->{$para}->[1]){
    $self->add_comment($section,$para,$comment);
  }else{
    $self->{$section}->{$para}->[1]=$comment;
  }
}

sub get_ini{
  my $self=shift;
  return $self->{INI};
}

sub save_ini{
  no strict "refs";
  my $self=shift;
  my $file=$self->get_ini;
  my $cm=$self->get_marker;
  open FH,">$file"||die"Unable to open $file: $!\n";
  flock(FH,LOCK_EX) or die "Unable to obtain file lock: $!\n";
  foreach my $section(sort keys %{$self}){
    print FH "[$section]\n" unless $section eq "INI" or $section eq "CM";
    foreach my $para(sort keys %{$self->{$section}}){
      print FH "$para = $self->{$section}{$para}[0]";
      if(defined $self->{$section}{$para}[1]){
        print FH "     $cm$self->{$section}{$para}[1]\n";
      }else{ print FH "\n"; }
    }
    print FH "\n" unless $section eq "INI" or $section eq "CM";
  }
  flock(FH,LOCK_UN) or die "Unable to unlock file: $!\n";
  close FH;
}

sub dmp{
  require Data::Dumper;
  my $self=shift;
  print Data::Dumper::Dumper($self);
}

sub deparse{
  my $tree=shift;
  my $deparsed={};
  for my $aref(@$tree){
    for my $sec(@$aref){
      my $hash=$deparsed->{$sec->[0]}={};
      for my $aref(@{$sec->[1]}){
        $hash->{$aref->[0]}=[$aref->[1]];
        if(my $cmmnt=$aref->[2]){
          $cmmnt=~s/^\s+[#;]//;
          push @{$hash->{$aref->[0]}},$cmmnt;
        }
      }
    }
  }
  return $deparsed;
}

1;
__END__

=head1 NAME

Config::Yacp - Yet Another Configuration file Parser

=head1 SYNOPSIS 

use Config::Yacp;
my $cfg=Config::Yacp->new("config.ini",";");

# Get the names of the sections
my @sections=$cfg->get_sections;

# Get the parameter names within a section
my @params = $cfg->get_parameters("Section1");

# Get the value of a specific parameter within a section
my $value = $cfg->get_value("Section1","Parameter1");

# Add a section
$cfg->add_section("Section3");

# Add a parameter and value to a section with a comment
$cfg->add_parameter("Section3","Key5","Value5","Comment");

# Change the value of a parameter within a section
$cfg->set_value("Section3","Key5","Value99");

# Delete a parameter and value in a section
$cfg->del_parameter("Section1","key1");

# Delete an entire section
$cfg->del_section("Section2");

# Add a comment to a section/parameter
$cfg->add_comment("Section3","key4","This is a comment");

# Change the comment
$cfg->set_comment("Section3","key4","New comment");

# Delete a comment
$cfg->del_comment("Section3","key4");

# Save the changes to the .ini file
$cfg->save_ini;

=head1 DESCRIPTION

=over 5

=item new

C<< my $comment_marker=";"; >>
C<< my $cfg=Config::Yacp->new("config.ini",$comment_marker); >>

This constructor returns a reference to a hash. It uses Parse::RecDescent and a
simple grammar to parse out the ini file, and put it into a hash. The ini files
are similar to those used by Windows, i.e. section names are surrounded by [],
and the parameter/values are separated by an = sign. The ini file can contain
a single line comment for each key/value. The comment must start with either a
semi-colon or a pound sign. The default comment marker is the pound sign. 

=item get_sections

C<< my @sections = $cfg->get_sections; >>

This method retrieves the section names in a list format

=item get_parameters

C<< my @params = $cfg->get_parameters("Section1"); >>

This method retrieves the parameter names for a given section and returns them
in a list format. This method will croak if a section name is not passed to it
or if the section name given to it does not exist.

=item get_value

C<< my $value = $cfg->get_value("Section1","Parameter1"); >>

This method retrieves the value of the section and parameter that are passed to
it. It will croak if either the section name or parameter name does not exist,
or if there aren't enough arguments passed to it.

=item get_comment

C<< my $comment = $cfg->get_comment("Section1","Parameter2"); >>

This method retrieve the comment associated with the Parameter if it exists. If
the comment does not exist, it will return with a warning.

=item add_section

C<< $cfg->add_section("Section3"); >>

This method will add a section into the object, but will not exist in the .ini
file until the save_ini method is called. This method will croak if the section
being added already exists within the object.

=item add_parameter

C<< $cfg->add_parameter("Section3","key5","value5","comment"); >>

This method will add a parameter and value to a specific section within the
object. The parameter will exist only within the object until the save_ini
method is called. This method will croak if it is passed an invalid section
name, or the parameter exists within the section. The comment is an optional
item that can be passed to the method.

=item add_comment

C<< $cfg->add_comment("Section1","key2","This is a comment"); >>

This method will add a comment to the section/parameter that is passed to it.
If that section/parameter has a comment associated with it, this method will
call the set_comment method, otherwise it will push the comment onto the
anonymous array.

=item set_value

C<< $cfg->set_value("Section3","key5","value9"); >>

This method will change the value of the specified section/parameter within the
object, and will write the change to the .ini file upon callinig the save_ini
method. This method will croak if either the section or parameter name does not
exist.

=item set_comment

C<< $cfg->set_comment("Section3","key5","This is a comment"); >>

This method will change the comment that is contained in the parameter that
is passed to it. If the comment doesn't exist for that parameter, it will
call the add_comment method, otherwise it will write over the comment.

=item del_parameter

C<< $cfg->del_parameter("Section3","key5"); >>

This method will delete the specified parameter within a section. The change
will occur within the object and is written out to the .ini file upon calling
the save_ini method. This method will croak if either the section or parameter
name is non-existent.

=item del_section

C<< $cfg->del_section("Section3"); >>

This method will delete the specified section inside the object. It will also
remove any parameters that were under that section heading. This method will
croak if the section does not exist.

=item del_comment

C<< $cfg->del_comment("Section1","key1"); >>

This method will delete the comment associated with the section/parameter
passed to it.

=item save_ini

C<< $cfg->save_ini; >>

This method will save the parameters that have been changed inside the object
back to the ini file that was specified when the object was created. For any
comments saved to the ini file, it will use the internal CM parameter, which
is the pound sign by default, unless it was set to a semi-colon at the creation
of the object. 

=back

=head1 EXPORT

None by default

=head1 ACKNOWLEDGEMENTS

I got the idea for this from the book "Data Munging with Perl", written by Dave Cross.

I would also like to thank everyone at PerlMonks.org who helped me with the
questions I had concerning the P::RD module

=head1 AUTHOR

Thomas J. Stanley Jr.

Thomas_J_Stanley@msn.com

I can also be found at http://www.perlmonks.org as TStanley. You can also
direct any questions concerning this module there

=head1 COPYRIGHT

=begin text

Copyright (C)2003 Thomas Stanley. All rights reserved. This program is free
software; you can distribute it and/or modify it under the same terms as Perl
itself.

=end text

=begin html

Copyright E<copy> 2003 Thomas Stanley. All rights reserved. This program is free
software; you can distribute it and/or modify it under the same terms as Perl
itself.

=end html

=head1 SEE ALSO

perl

Parse::RecDescent

Data::Dumper

Fcntl

Test::More

=cut

