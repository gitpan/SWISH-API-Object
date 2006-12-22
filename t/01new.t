use Test::More;

use SWISH::API::Object;
use File::Spec;
use Carp;
use Data::Dump qw( dump );

my $index = File::Spec->catfile('t', 'index.swish-e');
my $files = join(' ',
                 File::Spec->catfile('t', 'test.html'),
                 File::Spec->catfile('t', 'json.html'),
                 File::Spec->catfile('t', 'yaml.html'));
my $config = File::Spec->catfile('t', 'conf');
my $cmd    = "swish-e -i $files -f $index -c $config";

diag($cmd);
system($cmd);

if (-s $index)
{

    #diag("found $index");
    plan tests => 11;
}
else
{
    plan skip_all => 'no index found';
}

ok(
    my $swish =
      SWISH::API::Object->new(
                              indexes => [$index],
                              class   => 'My::Class'
                             ),
    "new object"
  );

#diag(dump($swish));

ok(my $results = $swish->query('yaml'), "query");

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
