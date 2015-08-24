# Introduction #

Bionic is the android libc. This is a component which is used by [LibPerl](LibPerl.md)

# Details #

## bionic master branch ##
The master branch of bionic grows and does not reflect what we have on older HTC G1.
However, the commit history of bionic does not allow us to checkout the exact bionic
that may match the old one we want. So, we finally decided to build [LibPerl](LibPerl.md) upon the latest bionic from the master branch.

## bionic binary on HTC G1 ##
  * does not have div\_t nor div(). Workaround: compile div.c independently and link manually.
  * does not have clearerr().

# Update 2010-04-05 #

We are no more supporting pre-1.6 phones.