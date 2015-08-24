# How do I "use" a Java class? #

## Sample in Java ##

Sample: how to to this, in "MyClass.java":

```
import org.apache.http.HttpResponse;
public class MyClass
{
  public HttpResponse instanceOfHttpResponse;
  public void MyClass
  {
    instanceOfHttpResponse = new HttpResponse(args...);
  }
}
```

in Perl?

## Sample in Perl ##

Answer, in MyClass.pm:

```
package MyClass.pm;
use PerlDroid::org::apache::http;

sub new
{
  my $instanceOfHttpResponse = $HttpResponse->new(args...); # Note the '$' sign
}
```

That's it!

## Idea ##

The original idea was that PerlDroid.pm would populate all namespaces at loading with stubs for class loading and method invoking. But because of possible name clash, you'll have to use the PerlDroid package that correspond to the Java package and it will import the classes you want.

In this case, it is like this:

In `.../PerlDroid/org/apache/http.pm`:

```
package PerlDroid::org::apache::http;
require Exporter;
our @ISA = qw(...);
our @EXPORT = qw($HttpResponse, ...);

use PerlDroid::org::apache::http::HttpResponse;
use PerlDroid::org::apache::http::...;

our $HttpResponse = bless {}, 'PerlDroid::org::apache::http::HttpResponse';
```

And in `.../PerlDroid/org/apache/http/HttpResponse.pm`:

```
package PerlDroid::org::apache::http::HttpResponse;

# Constructor
sub new
{
  shift;
  # See below for the XS constructor logic
  return XS_constructor('org/apache/http/HttpResponse', @_);
}

# for methods
sub AUTOLOAD {
  return XS_method($AUTOLOAD, @_)
}
```

Actually the constructor can also be treated with AUTOLOAD.

## Logic behind XS functions ##

XS\_constructor(class, args...)

  1. findclass(class) unless already loaded
  1. instantiate an object
  1. call class constructor with args
  1. return the object

XS\_method($autoload, $obj, @args):

  1. get obj type
  1. call $obj->$autoload(args)
  1. return result