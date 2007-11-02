use Test::More tests => 12;

SKIP: {

   eval { require SWISH::API  };

   skip "SWISH::API is not installed - can't do More with it...", 12 if $@;

   skip "SWISH::API 0.04 or higher required", 12 unless ($SWISH::API::VERSION && $SWISH::API::VERSION >= 0.04);

   require_ok('SWISH::API::Object');


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

}
