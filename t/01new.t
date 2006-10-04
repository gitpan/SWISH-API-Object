use Test::More;

use SWISH::API::Object;
use Path::Class;
use Carp;
use Data::Dump qw/dump/;

my $index = file('t', 'index.swish-e')->stringify;
my $file  = file('t', 'test.html')->stringify;
my $cmd = "swish-e -i $file -f $index";
#diag($cmd);
system($cmd);

if (-s $index)
{
    #diag("found $index");
    plan tests => 10;
}
else
{
    plan skip_all => 'no index found';
}

ok(
    my $swish =
      SWISH::API::Object->new(
                              indexes => [$index],
                              class   => 'My::Class',
                              stat    => 1
                             ),
    "new object"
  );

#diag(dump($swish));

ok(my $results = $swish->query('foo'), "query");

#diag(dump($results));

while (my $object = $results->next_result)
{
    #diag '-' x 60;
    #diag(dump $object);
    for my $prop ($swish->props)
    {
        ok(printf("%s = %s\n", $prop, $object->$prop), "property printed");
    }
}
