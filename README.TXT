'RM50 Manager' is a voice and rhythm kit editor for the Yamaha RM50 rhythm
sound module. It runs on Linux and Windows and probably also OS X (untested).
For more info about the Yamaha RM50 see:
http://www.linuxtech.net/musicgear/synth_yamaha_rm50.html


Linux instructions
==================

Prerequisites:


- Perl

  Perl should be installed by default on most distros, otherwise practically
  every distro has it in it's software repository


- Perl-Tk

  Perl-Tk is available in the software repositories of all major distros, the
  package is called either 'perl-tk' or 'perl-Tk' (with a capital 'T')


- MIDI::ALSA

  a Perl library module that provides MIDI functionality on Linux, you will
  have to install this from the source tarball as AFAIK no distro includes
  this yet. Get it from here: http://search.cpan.org/dist/MIDI-ALSA/ALSA.pm
  or install it via CPAN: cpan MIDI::ALSA


- Config::Simple

  another Perl library module required by rm50_manager. Install it from the
  software repository of your distro or via CPAN: cpan Config::Simple



Windows instructions
====================

Prerequisites:


- Perl

  there are a few version of Perl for Windows, the current Activestate version
  does not provide Perl-Tk so can't be used. I have successfully used
  Strawberry Perl 5.16.1.1 32 bit on Windows XP SP3.
  Get Strawberry Perl from here: http://strawberryperl.com/


- Perl-Tk

  After installing Strawberry Perl, you need to install Perl-Tk, this can be
  done from CPAN. Open a Windows command prompt and type the following (note
  the capital 'T'): cpan Tk

  You need to be connected to the internet to do this as this will contact the
  Strawberry Perl CPAN repository and download and install Perl-Tk
  automatically all in one go.


- Win32API-MIDI  ( http://search.cpan.org/dist/Win32API-MIDI/MIDI.pm )

  Just like the Perl-Tk module, the Win32API-MIDI module needs to be installed
  from CPAN over the internet. Again, type the following into an open Windows
  command prompt: cpan Win32API::MIDI


- Config::Simple

  another Perl library module required by rm50_manager. Install it from CPAN
  by typing the following into an open Windows command prompt:
  cpan Config::Simple




OS X
====

The RM50 Manager should run on OS X too (without MIDI support), as long as you
have Perl, Perl-Tk and the Config::Simple module installed. I don't have access
to any OS X machine so can't test this myself.

