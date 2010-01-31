use strict;
use warnings;
use Test::More;
use CSS::Selector::Parser 'parse_selector' => { -as => 'parse' };

is_deeply
  [ parse('#foo') ],
  [ [ { id => 'foo' } ] ];

is_deeply [ parse('#foo .bar, baz[quux]') ],
  [ 
    [ { id => 'foo' }, { combinator => ' ', class => 'bar' } ],
    [ { element => 'baz', attr => { quux => undef } } ],
  ];

is_deeply [ parse('#foo:first, .bar:nth(2)') ],
  [
    [ { id => 'foo', pseudo => { first => undef } } ],
    [ { class => 'bar', pseudo => { nth => 2 } } ],
  ];

is_deeply
  [ parse('foo#bar:baz.quux') ],
  [ parse('foo.quux:baz#bar') ],
;

done_testing();
