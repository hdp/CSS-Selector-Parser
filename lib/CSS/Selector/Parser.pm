package CSS::Selector::Parser;
# ABSTRACT: parse CSS selectors to Perl data structures

use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [ qw(parse_selector) ],
};

my $re_name       = qr/[-\w]+/;
# taken from HTML::Selector::XPath
my $re_attr_value = qr/^\[\s*([^~\|=\s]+)\s*([~\|]?=)\s*"([^"]+)"\s*\]/;
my $re_attr_exist = qr/^\[([^\]]*)\]/;
my $re_pseudo     = qr/^:([()a-z0-9_-]+)/;
my $re_combinator = qr/^(\s*[>+\s])/;
my $re_comma      = qr/^\s*,/;

sub parse_selector {
  local $_ = shift;
  my @rules;
  s/\s+$//;
  RULE: {
    #warn "RULE: $_\n";
    my $combinator;
    my @selector;
    SIMPLE: {
      s/^\s+//;
      #warn "SIMPLE: $_\n";
      my ($element, $id, $class, %attr, %pseudo);
      $element = $1 if s/^($re_name|\*)//;
      SUB: {
        $id = $1, redo SUB if s/^\#($re_name)//;
        if (s/^\.($re_name)//) {
          $class = join '.', grep(defined, $class, $1);
          redo SUB;
        }
        if (s/$re_attr_value//) {
          $attr{$1}{$2} = $3;
          redo SUB;
        }
        if (s/$re_attr_exist//) {
          $attr{$1} = undef unless exists $attr{$1};
          redo SUB;
        }
        # XXX grab :not first
        if (s/$re_pseudo//) {
          my $p = $1;
          if ($p =~ s/\((.+)\)$//) {
            $pseudo{$p} = $1;
          } else {
            $pseudo{$p} = undef;
          }
          redo SUB;
        }
      }

      my $simple = {
        element    => $element,
        id         => $id,
        class      => $class,
        attr       => \%attr,
        pseudo     => \%pseudo,
        combinator => $combinator,
      };
      for (keys %$simple) {
        delete $simple->{$_} unless defined $simple->{$_};
      }
      for (qw(attr pseudo)) {
        delete $simple->{$_} unless %{$simple->{$_}};
      }
      #warn Dumper($simple);
      push @selector, $simple;

      $combinator = undef;

      if (s/$re_combinator//) {
        $combinator = $1;
        redo SIMPLE;
      }

      push @rules, \@selector;
      redo RULE if s/$re_comma//;
      last RULE unless $_;
      die "fell off the end of parsing: $_\n";
    }
  }
  return @rules;
}

1;

__END__

=head1 SYNOPSIS

  use CSS::Selector::Parser 'parse_selector';

  my @rules = parse_selector('#foo .bar, baz:quux');
  # [ { id => 'foo' }, { class => 'bar', combinator => ' ' } ]
  # [ { element => 'baz', pseudo => { quux => undef } ]

=head1 DESCRIPTION

This module parses CSS selectors and gives back a series of Perl data
structures corresponding to the selectors.

=head1 FUNCTIONS

CSS::Selector::Parser uses L<Sub::Exporter>.  See its documentation for various
ways to customize exporting.

=head2 parse_selector

  my @rules = parse_selector($selector);

CSS selectors are mapped to Perl data structures.  Each set of selectors is
returned as an arrayref of hashrefs (see L</SYNOPSIS> for an example).

The hashrefs have:

=over

=item element

C<foo> in C<foo#bar.baz>.  

=item id

C<bar> in C<foo#bar.baz>.  Note: NOT C<[id="..."]>.

=item class

C<baz> in C<foo#bar.baz>.  Note: NOT C<[class="..."]>.

=item attr

A hashref of attribute selectors, each of which has a hashref of operators and
values:

  parse_selector('[foo="bar"]')
  # [ { attr => { foo => { '=' => 'bar' } } } ]

Attribute selectors can also test for presence:

  parse_selector('[foo]')
  # [ { attr => { foo => undef } } ]

=item pseudo

A hashref of pseudo-classes and their contents, if present:

  parse_selector(':active:nth(2)')
  # [ { pseudo => { active => undef, nth => 2 } } ]

=item combinator

All hashrefs after the first will have this.  One of C<<[ >+]>>.  See
L</SYNOPSIS> for an example.

=back

=head1 SEE ALSO

L<HTML::Selector::XPath>, from which I stole code

=cut
