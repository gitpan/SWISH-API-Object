use Test::More tests => 11;

use SWISH::API::Object;
use Carp;
use Data::Dump qw( dump );

my $index  = File::Spec->catfile('t', 'index.swish-e');

ok(
    my $swish =
      SWISH::API::Object->new(
                              indexes => [$index],
                              class   => 'My::Class',
                              serial_format => 'json'
                             ),
    "new object"
  );

#diag(dump($swish));

ok(my $results = $swish->query('json'), "query");

while (my $object = $results->next_result)
{
    #diag '-' x 60;
    #diag(dump $object);
    for my $prop ($swish->props)
    {
        ok(printf("%s = %s\n", $prop, $object->$prop), "property printed");
    }
}
