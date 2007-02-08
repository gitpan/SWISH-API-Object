package SWISH::API::Object;

use strict;
use warnings;
use Carp;

our $VERSION = '0.08';
use base qw( SWISH::API::Stat );

sub init
{
    my $self = shift;

    $self->SUPER::init(@_);    # Stat init()

    $self->mk_accessors(qw( properties class stash serial_format ));

    my $i = $self->indexes->[0];    # just use the first one for header vals

    unless ($self->properties && ref($self->properties))
    {
        $self->properties({});

        my @p = $self->handle->property_list("$i");
        for (@p)
        {
            $self->properties->{$_->name} = $_->id;
        }
    }

    my $d = $self->handle->header_value($i, 'Description') || '';
    my ($class, $format) = split(m/\ +/, $d);
    unless ($self->class)
    {
        if ($class && $class =~ m/class:(\S+)/)
        {
            $self->class($1);
        }
        else
        {
            $self->class('SWISH::API::Object::Result::Instance');
        }
    }
    unless ($self->serial_format)
    {
        if ($format && $format =~ m/format:(\S+)/)
        {
            $self->serial_format($1);
        }
        else
        {
            $self->serial_format('yaml');
        }
    }

    # this ISA trickery has 2 benefits:
    # (1) a default new() method
    # (2) easy accessor maker
    unless ($self->class->can('mk_accessors'))
    {
        no strict 'refs';
        push(@{$self->class . '::ISA'}, 'Class::Accessor::Fast');
    }

    $self->class->mk_accessors(keys %{$self->properties});

}

sub props
{
    my $self = shift;
    $self->{_props} ||= [sort keys %{$self->properties}];
    return @{$self->{_props}};
}

1;

package SWISH::API::Object::Results;
use strict;
use warnings;
use base qw( SWISH::API::More::Results );
use Carp;
use YAML::Syck ();
use JSON::Syck ();

sub next_result
{
    my $self = shift;
    my $r    = $self->SUPER::next_result(@_);
    return undef unless defined $r;
    return $self->make_object($r);
}

sub make_object
{
    my ($self, $result) = @_;
    my $sao   = $self->base;
    my $class = $sao->class;

    my %propvals;

    for my $p ($sao->props)
    {
        my $m = $sao->properties->{$p};

        if ($class->can($m))
        {
            $propvals{$p} = $class->$m($p);
        }
        else
        {
            my $v = $result->property($p);
            $propvals{$p} =
              defined($v) ? $self->deserialize($sao->serial_format, $v) : '';
        }

    }

    return $class->new(\%propvals, $sao->stash);
}

sub deserialize
{
    my $self = shift;
    my $f    = shift;
    my $v    = shift;

    if ($f eq 'yaml' && $v =~ m/^---/o)    # would substr() be faster?
    {
        my $s;
        eval { $s = YAML::Syck::Load($v); };
        if ($@)
        {
            croak "$@\ncan't deserialize\n$v";
        }
        return $s;
    }
    elsif ($f eq 'json' && $v =~ m/^[\{\[\"]/o)
    {
        my $s;
        eval { $s = JSON::Syck::Load($v); };
        if ($@)
        {
            croak "$@\ncan't deserialize\n$v";
        }
        return $s;
    }
    else
    {
        return $v;
    }
}

1;

__END__

=head1 NAME

SWISH::API::Object - return SWISH::API results as objects

=head1 SYNOPSIS

  use SWISH::API::Object;
  
  my $swish = SWISH::API::Object->new(
                    indexes     => [ qw( my/index/1 my/index/2 )],
                    class       => 'My::Class',
                    properties  => {
                        swishlastmodified => 'result_property_str',
                        myproperty        => 1,
                        },
                    stash       => {
                                dbh => DBI->connect($myinfo)
                                },
                    serial_format => 'yaml'
                    );
                    
  my $results = $swish->query('foo');
  
  while(my $object = $results->next_result)
  {
    # $object is a My::Class object
    for my $prop ($swish->props)
    {
        printf("%s = %s\n", $prop, $object->$prop);
    }
    
    # $object also has all methods of My::Class
    printf("mymethod   = %s\n", $object->mymethod);
  }



=head1 DESCRIPTION

SWISH::API::Object changes your SWISH::API::Result object into an object blessed
into the class of your choice.

SWISH::API::Object will automatically create accessor methods for every result
property you specify, or all of them if you don't specify any.

In addition, the result object will inherit all the methods and attributes of
the I<class> you specify. If your I<class> has a B<new()> method, it will be called
for you. Otherwise, a generic new() method will be used.

=head1 REQUIREMENTS

L<SWISH::API::More>

=head1 METHODS

SWISH::API::Object is a subclass of SWISH::API::More. Only new or overridden methods
are documented here.

=head2 new

=over

=item indexes

Same as in SWISH::API::More.

=item class

The class into which your Result object will be blessed. If not specified,
the index header will be searched according to the API specified in SWISH::Prog::Object,
and if no suitable class name is found, will default to 
C<SWISH::API::Object::Result::Instance>, which is a subclass of L<Class::Accessor::Fast>
(whose magic is inherited from L<SWISH::API::More>).


=item properties

A hash ref of PropertyNames and their formats. Keys are PropertyNames you'd like
made into accessor methods. Values are the SWISH::API::Property methods you'd like
called on each property value when it is set in the object.

The default is to use all PropertyNames defined in the index, with the default
format.

=item stash

Pass along any data you want to the Result object. Examples might include passing a DBI
handle so your object could query a database directly based on some method you define.


=item serial_format

What format should serialized Perl values be assumed to be? The default is C<yaml>.
You might also specify C<json>. If you have serialized values in some other format,
then you'll need to subclass SWISH::API::Object::Result and override deserialize().

See L<SWISH::Prog::Object>.

=back


=head2 class

Get/set the class name passed in new().

=head2 properties

Get/set the I<properties> hash ref passed in new().

=head2 props

Utitlity method. Returns sorted array of property names. Shortcut for:

 sort keys %{ $swish->properties }


=head1 SWISH::API::Object::Result

The internal SWISH::API::Object::Result class is used to extend the SWISH::API
next_result() method with a next_result_after() method. See SWISH::API::More for
documentation about how the *_after() methods work.

=head2 deserialize( I<format>, I<prop_val> )

Called for each property value. The I<format> deserialize() expects is based
on C<serial_format> in SWISH::API::Object->new().


=head1 SEE ALSO

L<SWISH::API>, L<SWISH::API::More>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
