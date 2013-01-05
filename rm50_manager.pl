#!/usr/bin/perl
#
#  Yamaha RM50 Manager version 1.1-beta1
#
#  Copyright (C) 2012 LinuxTECH.NET
#
#  Yamaha is a registered trademark of Yamaha Corporation.
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  version 2 as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

my $version="1.1-beta1";

use Tk;
use Tk::Pane;
use Tk::NoteBook;
#use Tk::Balloon;
use Tk::BrowseEntry;
use Tk::Optionmenu;
use Tk::JPEG;
use List::Util qw[min max];
use Config::Simple '-strict';

# initialize config file handler
my $cfg = new Config::Simple(syntax=>'ini');

# check if OS is Linux or Windows for OS specific sections
my $LINUX;
my $WINDOWS;
BEGIN{ if ($^O eq 'linux') { $LINUX=1; } elsif ($^O eq 'MSWin32') {$WINDOWS=1;} }

use if ($LINUX), 'MIDI::ALSA' => ('SND_SEQ_EVENT_PORT_UNSUBSCRIBED',
                                  'SND_SEQ_EVENT_SYSEX');

use if ($WINDOWS), 'Win32API::MIDI';

# initialise MIDI on Linux and Windows
my $midi;
my $midiIn;
my $midiOut;
if ($LINUX) {
    MIDI::ALSA::client("RM50 manager PID_$$",1,1,1);
    MIDI::ALSA::start();
} elsif ($WINDOWS) {
    $midi = new Win32API::MIDI;
}

# slider font size: 6 for Linux, 7 for Windows
my $f1; 
if ($LINUX) { $f1=6; } elsif ($WINDOWS) { $f1=7; }

# LCD style background color
my $LCDbg='#ECFFAF';
# title strips background and font color
my $Titlebg='#487890';
my $Titlefg='#F3F3F3';

my $modified=0;
my $filename='';
my $ryfilename='';

my %Scale_defaults=(
    -width        => 10,
    -length       => 200,
    -sliderlength => 16,
    -borderwidth  => 1,
    -showvalue    => 0,
    -resolution   => 1,
    -font         => "Sans $f1",
    -cursor       => 'hand2',
    -orient       => 'horizontal'
);
my %Scale_label_defaults=(
    -width        => 3,
    -height       => 1,
    -borderwidth  => 1,
    -font         => 'Sans 10',
    -foreground   => 'black',
    -background   => $LCDbg,
    -relief       => 'sunken'
);
my %Frame_defaults=(
    -borderwidth  => 2,
    -relief       => 'groove'
);
my %BEntry_defaults=(
    -state        => 'readonly',
    -font         => 'Sans 8',
    -style        => 'MSWin32',
);
my %choices_defaults=(
    -borderwidth  => 1,
    -relief       => 'raised',
    -padx         => 1,
    -pady         => 1
);
my %arrow_defaults=(
    -width        => 13,
    -height       => 12,
    -bitmap       => 'darrow'
);
my %Entry_defaults=(
    -borderwidth        => 1,
    -foreground         => 'black',
    -background         => $LCDbg,
    -highlightthickness => 0,
    -insertofftime      => 0,
    -insertwidth        => 1,
    -selectborderwidth  => 0
);
my %TitleLbl_defaults=(
        -font         => 'title',
        -foreground   => $Titlefg,
        -background   => $Titlebg
);

# RM50 Preset Waveforms
my @waves=qw(
     01:BDAnlg   02:BDDDryH  03:BDDDryT1 04:BDDDryT2  05:BDDDryT3 06:BDJazHi  07:BDJazLo  08:BDGate1  09:DGate2   10:BDProc1
     11:BDProc2  12:BDProc3  13:BDRoom   14:BDSFX     15:BDTekno  16:SDAnlg1  17:SDAnlg2  18:SDDryH   19:SDDryT1  20:SDDryT2
     21:SDDryT3  22:SDDryT4  23:SDWdRim  24:SDDrMtl   25:SDDry5H  26:SDDry5S  27:SDFab    28:SDGate1  29:SDGate2  30:SDGate3
     31:SDProcs  32:SDRevrb  33:SDRim    34:SDRoom1   35:SDRoom2  36:SDRoom3  37:SDRoom4  38:SDRoom5  39:SDSide   40:SDTekno
     41:SDBshTp  42:SDBshSw  43:HHAnlg   44:HHCls1a   45:HHCls1b  46:HHCls2   47:HHOpn1   48:HHOpn2   49:HHPedal  50:HHQtr
     51:CYChina  52:CYCrash  53:CYCrsh2  54:CYCup     55:CYCup2   56:CYRide1  57:CYRide2  58:TMDry1   59:TMDry2   60:TMJazz
     61:TMPwr1   62:TMPwr2   63:TMPwr3   64:TMRoom1   65:TMRoom2  66:TMTekno  67:Agogo    68:AnlgClp  69:AnlgCow  70:Bongo
     71:Cabasa   72:Claves   73:CongaHi  74:CongaLo   75:CongaMu  76:CongaSl  77:CongaHl  78:Cowbell  79:Guiro    80:Shaker
     81:Tambrin  82:TimblHi  83:TimblLo  84:TimCasc   85:Triangl  86:Whistle  87:WoodBlk  88:Ambient  89:BDAmb    90:SDAmb
     91:SideAmb  92:HatAmb   93:TomAmb   94:BDAttak   95:BDBody   96:Bottle   97:FingSnp  98:Noise    99:RimTrn1 100:RimTrn2
    101:Scratch 102:Tube    103:Stick   104:Typist   105:Metal1  106:PotTap  107:ShorTom 108:WudSlap 109:MuteDrm 110:PotMute
    111:Metal2  112:Metal3  113:CupHit  114:MetlWeb  115:OpenLo  116:GateMtl 117:Factory 118:Shakey  119:BuzStix 120:OilDrum
    121:Whup    122:MouthBD 123:TomMute 124:MouthS1  125:MouthCY 126:WoodHit 127:MouthS2 128:DigWave 129:P10Wave 130:P25Wave
    131:P50Wave 132:SawWave 133:TriWave 256:--off--- );

# RSC3071 Dave Weckl (Modern Jazz) card Waveforms
my @RSC3071=(
    '01:BD1',      '02:SD1 Hard', '03:SD1 Soft', '04:SD2 Hard', '05:SD2 Soft', '06:HHPedalL', '07:HHTip L',  '08:HHHvy L',
    '09:HHLightL', '10:HHOpen L', '11:HHTip R',  '12:HHHvy R',  '13:Tom 1',    '14:Tom 2',    '15:Tom 3',    '16:Tom 4',
    '17:Cow Tip',  '18:Cow Open' );

# RSC3072 Tommy Aldridge (Heavy Metal) card Waveforms
my @RSC3072=(
    '01:BD1',      '02:SD1 Soft', '03:SD1 Hard', '04:SD2 Soft', '05:SD2 Hard', '06:SD3 Soft', '07:SD3 Hard', '08:HHPedal',
    '09:HHMed',    '10:HHHvy',    '11:HHOpen',   '12:Tom 1',    '13:Tom 2',    '14:Tom 3',    '15:Tom 4',    '16:Effect',
    '17:Cowbell',  '18:Cymbell' );

# RSC3073 Matt Sorum (Rock) card Waveforms
my @RSC3073=(
    '01:BD1',      '02:SD1 Hard', '03:SD2 Hard', '04:SD2 Soft', '05:SD3 Hard', '06:SD4 Hard', '07:HHClosed', '08:HHHvy',
    '09:HHQtr',    '10:HHOpen',   '11:Tom 1',    '12:Tom 2',    '13:Tom 3',    '14:Tom 4',    '15:Cymbell' );

# RSC3074 Peter Erskine (Jazz) card Waveforms
my @RSC3074=(
    '01:Rec BD p', '02:Rec BD f', '03:Jaz BD p', '04:JazBDsfz', '05:JazSnr p', '06:JazSnr f', '07:Rec Snr',  '08:BrshHit1',
    '09:BrshTap1', '10:BrshTap2', '11:Sweep',    '12:Brush Up', '13:HH Pedal', '14:HH Tip L', '15:HH Tip R', '16:HH ClHvy',
    '17:HH1/2 Op', '18:HH Open',  '19:JazzTom1', '20:JazzTom2', '21:RackTom1', '22:RackTom2', '23:RackTom3', '24:FloorTom' );

# RSC3001 Percussion card Waveforms
my @RSC3001=(
    '01:BongoHi2', '02:BongoLo2', '03:Cabasa 2', '04:Claps 1',  '05:Claps 2',  '06:Castanet', '07:Cuica',    '08:Maracas',
    '09:Pandiero', '10:Shekele1', '11:Shekele2', '12:Shaker 2', '13:Surdo',    '14:TemplBlk', '15:TalkDrum', '16:Tamborim',
    '17:Vibraslp', '18:Chaxixi1', '19:Chaxixi2', '20:Tabla 1',  '21:Tabla 2',  '22:TimbalRl', '23:Timbale2', '24:Timpani' );

# RSC3002 FX Drums card Waveforms
my @RSC3002=(
    '01:Ambient',  '02:Bang',     '03:BD 1',     '04:BD 2',     '05:BigBang',  '06:Clap',     '07:Metal 1',  '08:MiniCym',
    '09:Donk',     '10:Door',     '11:Tube 1',   '12:Drum 1',   '13:Metal 2',  '14:Analog',   '15:Dunk',     '16:Metal 3',
    '17:Metal 4',  '18:Cow',      '19:Nurg',     '20:Punch',    '21:Pot',      '22:Scratch',  '23:Vibro',    '24:SD 1', 
    '25:Squeek',   '26:Zap',      '27:Zing',     '28:AmbientR' );

# RSC3003 House & Rap card Waveforms
my @RSC3003=qw(
    01:  02:  03:  04:  05:  06:  07:  08:
    09:  10:  11:  12:  13:  14:  15:  16:
    17:  18:  19:  20:  21:  22:  23:  24:
    25:  26:  27:  28:  29:  30:  31:  32: );

# RSC3004 Dance & Soul card Waveforms
my @RSC3004=qw(
    01:TightBD  02:AlrBD    03:ElectrBD 04:FloppyBD 05:SoftBD   06:WhamBD   07:TightSN  08:EffexSN  09:ClankSN  10:SplatSN
    11:SmallSN  12:RingSN   13:HHClose1 14:HHClose2 15:HHClose3 16:HHOpen   17:RimClunk 18:NoizClap 19:Tambo    20:Triangle
    21:BabyMrcs 22:Maracas  23:Shaker   24:CabasHit 25:TamSnap  26:CongaRub 27:SkinHit  28:Blocko   29:Snatch   30:AnaNoiz1
    31:AnaNoiz2 32:GTRNoiz );

# W7701 / W5501 Sax 1 card Waveforms (4 waves)
my @W7701=(
    '01:TSaxSoft', '02:TSaxHard', '03:ASaxSoft', '04:ASaxHard');

# W7702 / W5502 Drums 1 card Waveforms (12 waves)
my @W7702=(
    '01:Kick',     '02:SD 1 Dry', '03:SD 1 Rim', '04:SD 2',     '05:SD 3',     '06:Tom 1',    '07:Tom 2',    '08:HH Light',
    '09:HH Mid',   '10:HH Heavy', '11:HH Open',  '12:HH Pedal');

# W7704 / W5504 Brass Section card Waveforms (6 waves)
my @W7704=(
    '01:Trumpets', '02:Tenors',   '03:Baritone', '04:Blast',    '05:Roll',     '06:Sax Pad');

# W7705 / W5505 String Section card Waveforms (2 waves)
my @W7705=(
    '01:Strings',  '02:Pizz');

# W7731 / W5531 Syn Wave 1 card Waveforms (16 waves)
my @W7731=(
    '01:Syn Brs1', '02:AnlgSaw3', '03:Pan Pipe', '04:NewroStr', '05:Glasphon', '06:TwinBell', '07:Slap E.P', '08:W Steel',
    '09:MetalSaw', '10:Keen',     '11:Bell Pad', '12:Or.Click', '13:ProcesBD', '14:ProcesSD', '15:ProcesHH', '16:TuttiHit');

# W7732 / W5532 Syn Wave 2 card Waveforms (9 waves)
my @W7732=(
    '01:AnaBass1', '02:AnaBass2', '03:AnaStr 1', '04:AnaStr 2', '05:AnaStr 3', '06:CS80 Brs', '07:AnaBrs 2', '08:AnaLead',
    '09:NoiseMix');

# W7751 / W5551 Rock & Pop card Waveforms (28 waves)
my @W7751=(
    '01:Power BD', '02:Tight BD', '03:MediumSD', '04:Light SD', '05:Power SD', '06:PowerTom', '07:Syn Tom',  '08:HHclosed',
    '09:HH open',  '10:Claps',    '11:Clave',    '12:Belltree', '13:PickBass', '14:SlapBass', '15:SynBass',  '16:Gtr Pluk',
    '17:Clavi Wv', '18:EP Wave',  '19:SynOrgan', '20:MiniSolo', '21:MiniSaw',  '22:MatrixWv', '23:Quack Wv', '24:Brth Flt',
    '25:Trumbone', '26:BrassWv1', '27:BrassWv2', '28:Typist');

# W7752 / W5552 House & Latin card Waveforms (37 waves)
my @W7752=qw(
    01:TronixBD 02:RebelBD  03:BoomBD   04:MaddySN  05:SplashSN 06:RimhitSN 07:TrashSN  08:CheapSN  09:AnaCow   10:AnaClap
    11:AnaTom   12:AnaClave 13:AnaConga 14:AnaHHCL  15:AnaHHOP  16:NoizeHit 17:RockMe!  18:RollMe!  19:Haaaay!  20:Yeeeah!
    21:Synbass1 22:Synbass2 23:GtrPluck 24:CongaSlp 25:CongaLow 26:CongaHi  27:CongaSl  28:CongaHl  29:CongaDmp 30:Timbale
    31:Shaker   32:Cabasa   33:Whistle  34:Tambo    35:Agogo    36:Bongo    37:Tabla );

# Internal 512K RAM Waveforms (can contain max. 64 waves)
my @WaveRAM=(); for (my $nr=1; $nr<=64; $nr++) { $WaveRAM[$nr-1]=(sprintf("%02d",$nr)).':WaveRAM'; }

# RM50 Preset/Variation banks voice names
my @BD_voices=(
    '01:DR Kikin', '02:DR Hard',  '03:DR Boom',  '04:DR Danc1', '05:DR Danc2', '06:DR Danc3', '07:DR Danc4', '08:DR Jazz1',
    '09:DR Maple', '10:DR Pop1',  '11:DR Byter', '12:DR LoCal', '13:DR Beef',  '14:DR Clean', '15:DR Click', '16:DR Fuzzy',
    '17:DR Kinta', '18:DR Punch', '19:DR Round', '20:DR Slap1', '21:DR Slap2', '22:DR Solid', '23:DR Stud1', '24:DR Stud2',
    '25:DR Thump', '26:DR Woof',  '27:DR Arid',  '28:DR Huge',  '29:DR Live',  '30:JZ Lite',  '31:JZ DbHd1', '32:JZ DbHd2',
    '33:JZ Loose', '34:JZ Hard',  '35:JZ Swing', '36:JZ Swang', '37:JZ Smith', '38:RM Big',   '39:RM Pow',   '40:RM Boo',
    '41:RM Def',   '42:RM Lizrd', '43:RM Crnch', '44:RM Piles', '45:RM Open',  '46:RM AirHd', '47:RM Tight', '48:RM Soft',
    '49:RM Jazz',  '50:RM Nuke',  '51:RM March', '52:RV Bambi', '53:RV Kick',  '54:RV Mondo', '55:RV Balad', '56:RV LoHz',
    '57:RV Orch',  '58:RV Arena', '59:GT Tyron', '60:GT Mutha', '61:GT Tight', '62:GT Noizy', '63:GT Homer', '64:GT Aero',
    '65:GT Fist',  '66:GT Stuff', '67:GT Blanc', '68:GT Snack', '69:GT Rattl', '70:GT Klass', '71:GT 5 Bar', '72:GT Grind',
    '73:AN Antek', '74:AN 919',   '75:AN 929',   '76:AN 939',   '77:AN 818',   '78:AN Sinus', '79:AN Booom', '80:EL Kirk',
    '81:EL Simm',  '82:EL Paso',  '83:EL Prinz', '84:EL Rap',   '85:EL Efant', '86:EL Ectro', '87:EL Ouise', '88:EL Ektrn',
    '89:EL Sid',   '90:EL Tech1', '91:EL Tech2', '92:FX Klam',  '93:FX Klang', '94:FX Hell',  '95:FX IYF',   '96:FX Trash',
    '97:FX Zilla', '98:FX Atom',  '99:FX Futur', '100:FX TNT',  '101:FX Cicad', '102:FX Delay');

my @SD_voices=(
    '01:DR HiPop', '02:DR Digit', '03:DR Rim1',  '04:DR Damn',  '05:DR Custr', '06:DR Basic', '07:DR Kindl', '08:DR Smack',
    '09:DR M.O.R', '10:DR Metl1', '11:DR Brass', '12:DR Steel', '13:DR Rim2',  '14:DR Tite1', '15:DR Tite2', '16:DR Maple',
    '17:DR Real1', '18:DR Norm',  '19:DR 400',   '20:DR Marly', '21:DR Danc1', '22:DR Danc2', '23:DR Danc3', '24:DR Arid1',
    '25:DR Arid2', '26:DR Arid3', '27:DR Arid4', '28:DR Rim3',  '29:DR Rim4',  '30:DR Vergn', '31:DR Wood',  '32:DR Real2',
    '33:DR Krack', '34:JZ Playr', '35:JZ Cool',  '36:JZ Brsa1', '37:JZ Swpa1', '38:JZ Brsb1', '39:JZ Swpb1', '40:JZ Swsh1',
    '41:JZ Brsa2', '42:JZ Swpa2', '43:JZ Brsb2', '44:JZ Swpb2', '45:JZ Swsh2', '46:RM Burnn', '47:RM Crank', '48:RM Karim',
    '49:RM Obese', '50:RM Diet',  '51:RM Tubby', '52:RM No FC', '53:RM 9volt', '54:RV Gospl', '55:RV TheDB', '56:RV Spike',
    '57:RV Atom',  '58:RV Sizzl', '59:RV Head',  '60:RV Biznz', '61:RV Wham',  '62:RV Bam',   '63:RV Thanx', '64:RV Canon',
    '65:RV Bryte', '66:RV Ghost', '67:RV IYF',   '68:GT Shock', '69:GT HiFab', '70:GT Short', '71:GT LoFab', '72:GT Sucks',
    '73:GT Thump', '74:GT EatIt', '75:GT Whip',  '76:GT Tasty', '77:GT Anvil', '78:GT Stape', '79:GT Erake', '80:GT Fable',
    '81:GT Wacko', '82:AN Orexk', '83:AN 919',   '84:AN 818',   '85:AN 929',   '86:AN 828',   '87:EL Down',  '88:EL Power',
    '89:EL Simm',  '90:FX Tech',  '91:FX 9Roll', '92:FX Ugly',  '93:FX Pain',  '94:FX Undys', '95:FX Igor',  '96:FX Spit',
    '97:FX Sneez', '98:FX Cough', '99:FX Bakup', '100:FX Ruff', '101:FX Jam',  '102:FX Spew', '103:FX Hack', '104:SS Ambi1',
    '105:SS Ambi2', '106:SS Dryer', '107:SS Dry', '108:SS Count');

my @TM_voices=(
    '01:DR Nice1', '02:DR Nice2', '03:DR Nice3', '04:DR Nice4', '05:DR Slap1', '06:DR Slap2', '07:DR Slap3', '08:DR Slap4',
    '09:DR Mapl1', '10:DR Mapl2', '11:DR Mapl3', '12:DR Mapl4', '13:DR Powr1', '14:DR Powr2', '15:DR Powr3', '16:DR Powr4',
    '17:DR Danc1', '18:DR Danc2', '19:DR Danc3', '20:DR Danc4', '21:DR Jazz1', '22:DR Jazz2', '23:DR Jazz3', '24:DR Jazz4',
    '25:RM Bop1',  '26:RM Bop2',  '27:RM Bop3',  '28:RM Bop4',  '29:RM Metl1', '30:RM Metl2', '31:RM Metl3', '32:RM Metl4',
    '33:RM Metl5', '34:RM Metl6', '35:RM Klip1', '36:RM Klip2', '37:RM Klip3', '38:RM Klip4', '39:RM Wet1',  '40:RM Wet2',
    '41:RM Wet3',  '42:RM Wet4',  '43:RM Hard1', '44:RM Hard2', '45:RM Hard3', '46:RM Hard4', '47:RV Atom1', '48:RV Atom2',
    '49:RV Atom3', '50:RV Atom4', '51:RV Huge1', '52:RV Huge2', '53:RV Huge3', '54:RV Huge4', '55:RV Stik1', '56:RV Stik2',
    '57:RV Stik3', '58:RV Stik4', '59:RV Stad1', '60:RV Stad2', '61:RV Stad3', '62:RV Stad4', '63:RV Ambi1', '64:RV Ambi2',
    '65:RV Ambi3', '66:RV Ambi4', '67:GT Tite1', '68:GT Tite2', '69:GT Tite3', '70:GT Tite4', '71:AN Sine1', '72:AN Sine2',
    '73:AN Sine3', '74:AN Sine4', '75:EL Simm1', '76:EL Simm2', '77:EL Simm3', '78:EL Simm4', '79:EL Phew1', '80:EL Phew2',
    '81:EL Phew3', '82:EL Phew4', '83:FX Hurt1', '84:FX Hurt2', '85:FX Hurt3', '86:FX Hurt4', '87:FX Cyn1',  '88:FX Cyn2',
    '89:FX Cyn3',  '90:FX Cyn4',  '91:ET Buru1', '92:ET Buru2', '93:ET Buru3', '94:ET BStik', '95:FX Wack1', '96:FX Wack2',
    '97:FX Wack3', '98:FX Wack4', '99:FX Rvrs1', '100:FX Rvrs2', '101:FX Rvrs3', '102:FX Rvrs4', '103:FX Flng1', '104:FX Flng2',
    '105:FX Flng3', '106:FX Flng4', '107:FX Solo');

my @CY_voices=(
    '01:HH RYCl1', '02:HH RYQt1', '03:HH RYHf1', '04:HH RYOp1', '05:HH RYPd1', '06:HH RYCl2', '07:HH RYOp2', '08:HH RkClR',
    '09:HH RkkCl', '10:HH RkQrt', '11:HH RkHlf', '12:HH RkOpn', '13:HH RkPed', '14:HH AmCls', '15:HH AmOpn', '16:HH AmPed',
    '17:HH VxCls', '18:HH VxOpn', '19:HH TecC1', '20:HH TecC2', '21:HH TecC3', '22:HH TecO1', '23:HH TecO2', '24:HH Pitch',
    '25:HH Stand', '26:HH AnCl1', '27:HH AnOp1', '28:HH AnCl2', '29:HH AnOp2', '30:RD Medi1', '31:RD EdgCp', '32:RD Bell',
    '33:RD Flat',  '34:RD Rock',  '35:RD RckBl', '36:RD Jazz1', '37:RD Jazz2', '38:RD Long',  '39:RD Medi2', '40:RD Sizzl',
    '41:RD FxBel', '42:RD FxRid', '43:CR Crsh1', '44:CR Crsh2', '45:CR Dark1', '46:CR High1', '47:CR Dark2', '48:CR High2',
    '49:CR Rock1', '50:CR Rock2', '51:CR Choke', '52:CS Spls1', '53:CS Spls2', '54:CS Spls3', '55:CH Chin1', '56:CH Ride',
    '57:CH Short', '58:CH Chin2', '59:CH Gong',  '60:CH Strok', '61:FX Big1',  '62:FX Gong',  '63:FX Elekt', '64:FX Revrs',
    '65:FX Tecko');

my @PC_voices=(
    '01:LP AgoHi', '02:LP AgoLo', '03:LP BngHi', '04:LP BngLo', '05:LP Caba1', '06:LP Caba2', '07:LP Caba3', '08:LP Caba4',
    '09:LP Clave', '10:LP Qnto1', '11:LP Cong1', '12:LP Tumb1', '13:LP Slap1', '14:LP Low1',  '15:LP Mute1', '16:LP Heel1',
    '17:LP CgHi2', '18:LP CgLo2', '19:LP Slap2', '20:LP Mute2', '21:LP Heel2', '22:LP Cow1',  '23:LP Cow2',  '24:LP Cow3',
    '25:LP Guiro', '26:LP Shak1', '27:LP Shak2', '28:LP Tamb1', '29:LP Tamb2', '30:LP Tamb3', '31:LP Tmpl1', '32:LP Tmpl2',
    '33:LP Tmpl3', '34:LP Tmpl4', '35:LP TimH1', '36:LP TimL1', '37:LP TimH2', '38:LP TimL2', '39:LP Casc1', '40:LP Casc2',
    '41:LP Trian', '42:LP Whist', '43:PC Log1',  '44:PC Log2',  '45:PC Log3',  '46:PC Log4',  '47:PC Talk1', '48:PC Talk2',
    '49:PC Yoru1', '50:PC Yoru2', '51:PC Yoru3', '52:PC Yoru4', '53:PC Bott1', '54:PC Bott2', '55:PC Bott3', '56:PC Bott4',
    '57:PC Clap1', '58:PC Clap2', '59:PC AnaMu', '60:PC Snap',  '61:PC MeloB', '62:PC Metal', '63:PC PopM1', '64:PC PopM2',
    '65:PC PopM3', '66:PC PopM4', '67:PC TekD');

my @SE_voices=(
    '01:FX 7-11',  '02:FX B-Ben', '03:FX Joker', '04:FX Tubey', '05:FX Daiko', '06:FX Mello', '07:FX Door',  '08:FX Zero',
    '09:FX Blip',  '10:FX Bubbl', '11:FX Canes', '12:FX OilDr', '13:FX Sheet', '14:FX Sword', '15:FX Stab',  '16:FX Gongy',
    '17:FX Robot', '18:FX R2D2',  '19:FX RvCrs', '20:FX Scene', '21:FX Scrat', '22:FX Shui',  '23:FX Snark', '24:FX Spark',
    '25:FX Alien', '26:FX Steps', '27:FX Stix',  '28:FX Wiggy', '29:FX Falic', '30:FX Afro',  '31:FX Blow',  '32:FX Log',
    '33:FX Metal', '34:FX Pip',   '35:FX Revrs', '36:FX Rezzo', '37:FX Wet',   '38:FX BDMth', '39:FX S1Mth', '40:FX S2Mth',
    '41:FX S3Mth', '42:FX CYMth', '43:FX HCMth', '44:FX HOMth', '45:FX Type',  '46:FX Heart', '47:FX Tape',  '48:BA Nasti',
    '49:BA KillB', '50:BA Softa', '51:BA 30');

my @IMX_voices=(); for (my $nr=1; $nr<=128; $nr++) { $IMX_voices[$nr-1]=(sprintf("%02d",$nr)).':UserVoice'; }

my @CMX_voices=(); for (my $nr=1; $nr<=128; $nr++) { $CMX_voices[$nr-1]=(sprintf("%02d",$nr)).':UserVoice'; }

# RSC3001 Percussion card voice names
my @RSC3001_voices=(
    '01:L.Bg Slp', '02:Cabasa',   '03:Cuica Lo', '04:Pandiero', '05:ShekereD', '06:TemplBlk', '07:H.Bg Slp', '08:Castanet', 
    '09:MaracasD', '10:Rice Shk', '11:ShekereT', '12:Surdo',    '13:Tamborim', '14:Tabla Lo', '15:Caxixi L', '16:TimbalRl',
    '17:Timpani',  '18:Clap 2',   '19:TalkDr L', '20:Tabla Hi', '21:Caxixi H', '22:Timbal H', '23:Timbal L', '24:Clap 3',
    '25:TalkDr H', '26:Cuica Hi', '27:AnaCowbl', '28:TimPaira', '29:Tambdiro', '30:Squeeze',  '31:Vibraslp', '32:Den Den' );

# RSC3002 FX Drums card voice names
my @RSC3002_voices=qw(
    01:SwishHat  02:SwishWnd  03:BigDoor   04:MotorSnr  05:BuickKik  06:Beater    07:Growler   08:ShokClap
    09:MtlBongo  10:MTLonMTL  11:RicoTom   12:SnareAir  13:DarkTom   14:WhaBongo  15:UpSplash  16:TomsFlor
    17:TubeArgh  18:SnapESnr  19:CANtoCAN  20:TinyGong  21:PitchMtl  22:MtlFence  23:BigShot   24:Ringer
    25:Scratch   26:Them      27:CannonSn  28:Whales    29:EastPerc  30:FlyBy     31:ShockHat  32:FrogDrum );

# RSC3003 House & Rap card voice names
my @RSC3003_voices=qw(
    01:KickTite  02:KickDeep  03:KickAmbi  04:KickDirt  05:KickBend  06:KickRoom  07:EfexAaah  08:EfexJung
    09:EfexNoiz  10:EfexTape  11:EfexItts  12:EfexEizz  13:EfexGlas  14:EfexDaah  15:EfexDaba  16:EfexMetl
    17:EfexScra  18:EfexGtr!  19:HatsClos  20:HatsOpen  21:PercCaba  22:PercBlok  23:PercFing  24:PercTamb
    25:PercBlip  26:PercMara  27:SnarHigh  28:SnarLoos  29:SnarDirt  30:SnarTune  31:SnarFlat  32:Snar919! );

# RSC3004 Dance & Soul card voice names
my @RSC3004_voices=qw(
    01:KickTite  02:KickAiry  03:KickElec  04:KickFlop  05:KickKlik  06:KickHolo  07:SnarHigh  08:SnarCamo
    09:SnarKlnk  10:SnarSwat  11:SnarBaby  12:SnarRing  13:HatsCls1  14:HatsCls2  15:HatsCls3  16:HatsOpn1
    17:RimSnare  18:PercClap  19:PercTamb  20:PercAngl  21:PercMrc1  22:PercMrc2  23:PercShkr  24:PercCabs
    25:PercSnap  26:PercCRub  27:PercSkin  28:PercBlok  29:EfexGrab  30:EfexNoiz  31:EfexNoyz  32:EfexGtr! );

# RSC3071 Dave Weckl card voice names
my @RSC3071_voices=(
    '01:BD1',      '02:BD2',      '03:SD1',    '04:SD2',     '05:SD3',      '06:Foot L',   '07:Closed L', '08:MedCls L',
    '09:MedOpn L', '10:ShouldrL', '11:Open L', '12:Tip R',   '13:ShouldrR', '14:T/SRight', '15:Tom 1',    '16:Tom 2',
    '17:Tom 3',    '18:Tom 4',    '19:Tom 1B', '20:Tom 2B',  '21:Tom 3B',   '22:Tom 4B',   '23:Ride',     '24:RideBell',
    '25:Splash',   '26:Crash',    '27:China',  '28:Cowbel1', '29:Cowbel2',  '30:XFadeCow', '31:Crosstik', '32:Choker' );

# RSC3072 Tommy Aldridge voice names
my @RSC3072_voices=(
    '01:BD1 L', '02:BD1 R',  '03:BD1 Dry',  '04:BD2',      '05:SD1',      '06:SD2',      '07:SD3',      '08:SD4',
    '09:SD5',   '10:Foot',   '11:Closed',   '12:Shld Hvy', '13:Open',     '14:Tip/Shld', '15:Tom1',     '16:Tom2',
    '17:Tom3',  '18:Tom4',   '19:Tom5',     '20:Tom6',     '21:Cowbell',  '22:Crash',    '23:China',    '24:Ridebel',
    '25:Ride',  '26:Splash', '27:Pwr Tm 1', '28:Pwr Tm 2', '29:Pwr Tm 3', '30:Pwr Tm 4', '31:Pwr Tm 5', '32:Pwr Tm 6' );

# RSC3073 Matt Sorum card voice names
my @RSC3073_voices=(
    '01:BD1 L',    '02:BD1 R',    '03:BD1 Dry',  '04:BD 2',     '05:SD1',      '06:SD2',      '07:SD3',      '08:SD4',
    '09:SD5',      '10:Tip',      '11:1/4 Open', '12:Open',     '13:Foot',     '14:Tom 1',    '15:Tom 2',    '16:Tom 3',
    '17:Tom 4',    '18:Tom 5',    '19:Tom 6',    '20:Tom 7',    '21:Tom 8',    '22:Cowbell',  '23:Crash Hi', '24:China',
    '25:RideBell', '26:Big Bang', '27:Gong',     '28:Crash Lo', '29:Pwr Tm 2', '30:Pwr Tm 3', '31:Pwr Tm 4', '32:Shoulder' );

# RSC3074 Peter Erskine voice names
my @RSC3074_voices=(
    '01:Rec BD p', '02:Rec BD f', '03:RecBDp/f', '04:Jaz BD p', '05:JazBDp/f', '06:JazBDsfz', '07:Jazz SD',  '08:Rec SD',
    '09:BrshHit1', '10:BrshTap1', '11:BrshTap2', '12:Sweep',    '13:Brush Up', '14:Crosstik', '15:HH Pedal', '16:HH Tip L',
    '17:HH Tip R', '18:HH ClHvy', '19:HH1/2 Op', '20:HH Open',  '21:JazzTom1', '22:JazzTom2', '23:RackTom1', '24:RackTom2',
    '25:RackTom3', '26:Flr Tom1', '27:Flr Tom2', '28:SizzCym',  '29:Ride',     '30:Ridebell', '31:Crash',    '32:China' );

# preset voice bank mappings
my %prevcehash=(
    'P-BD'=>\@BD_voices, 'P-SD'=>\@SD_voices, 'P-TM'=>\@TM_voices, 'P-CY'=>\@CY_voices,
    'P-PC'=>\@PC_voices, 'P-SE'=>\@SE_voices );

# internal variation and user voice bank mappings
my %intvcehash=(
    'I-BD'=>\@BD_voices, 'I-SD'=>\@SD_voices, 'I-TM'=>\@TM_voices, 'I-CY'=>\@CY_voices,
    'I-PC'=>\@PC_voices, 'I-SE'=>\@SE_voices, 'I-MX'=>\@IMX_voices );

# data card variation and user voice bank mappings
my %crdvcehash=(
    'C-BD'=>\@BD_voices, 'C-SD'=>\@SD_voices, 'C-TM'=>\@TM_voices, 'C-CY'=>\@CY_voices,
    'C-PC'=>\@PC_voices, 'C-SE'=>\@SE_voices, 'C-MX'=>\@CMX_voices );

# wave card voice bank mappings (SY55/SY77 waveform cards don't contain voices so the RM50
# autogenerates a default voice for each waveform, therefore we can reuse the waveform name lists)
my %wvevcehash=(
    'RSC3001' => \@RSC3001_voices, 'RSC3002' => \@RSC3002_voices,
    'RSC3003' => \@RSC3003_voices, 'RSC3004' => \@RSC3004_voices,
    'RSC3071' => \@RSC3071_voices, 'RSC3072' => \@RSC3072_voices,
    'RSC3073' => \@RSC3073_voices, 'RSC3074' => \@RSC3074_voices,
    'W7701'   => \@W7701,   'W7702'   => \@W7702,   'W7704'   => \@W7704,   'W7705'   => \@W7705,
    'W7731'   => \@W7731,   'W7732'   => \@W7732,   'W7751'   => \@W7751,   'W7752'   => \@W7752 );

# hash containing actual available voice banks on a bare RM50 (no cards)
my %voiceshash=(%prevcehash, %intvcehash);

# map banks to bank numbers used by parameter change messages 
my %bankshash=(
                'P-BD'=>0,  'P-SD'=>2,  'P-TM'=>4,  'P-CY'=>6,  'P-PC'=>8,  'P-SE'=>10,
    'I-MX'=>12, 'I-BD'=>14, 'I-SD'=>16, 'I-TM'=>18, 'I-CY'=>20, 'I-PC'=>22, 'I-SE'=>24,
    'C-MX'=>26, 'C-BD'=>28, 'C-SD'=>30, 'C-TM'=>32, 'C-CY'=>34, 'C-PC'=>36, 'C-SE'=>38,
    'W-S1'=>40, 'W-S2'=>42, 'W-S3'=>44 );

# Velocity Curves
my @vlcurves=qw(
    1:Linear 2:Constant1 3:Constant2  4:Offset1     5:Offset2     6:Hard1
    7:Hard2  8:Easy1     9:Easy2     10:Crossfade1 11:Crossfade2 12:Crossfade3 );

# Wave Cards (the RM50 can use RY30, SY55 and SY77 wave cards)
my @wavecards=( ' -- empty slot -- ',
    'RSC3001: Percussion', 'RSC3002: FX Drums',       'RSC3003: House & Rap', 'RSC3004: Dance & Soul',
    'RSC3071: Dave Weckl', 'RSC3072: Tommy Aldridge', 'RSC3073: Matt Sorum',  'RSC3074: Peter Erskine',
    'W7701: Sax 1',        'W7702: Drums 1',          'W7704: Brass Section', 'W7705: String Section',
    'W7731: Syn Wave 1',   'W7732: Syn Wave 2',       'W7751: Rock & Pop',    'W7752: House & Latin' );

# map banks names to waveform lists
my %wavehash=( 'Preset'  => \@waves,   'IntRAM'  => \@WaveRAM,
    'RSC3001' => \@RSC3001, 'RSC3002' => \@RSC3002, 'RSC3003' => \@RSC3003, 'RSC3004' => \@RSC3004,
    'RSC3071' => \@RSC3071, 'RSC3072' => \@RSC3072, 'RSC3073' => \@RSC3073, 'RSC3074' => \@RSC3074,
    'W7701'   => \@W7701,   'W7702'   => \@W7702,   'W7704'   => \@W7704,   'W7705'   => \@W7705,
    'W7731'   => \@W7731,   'W7732'   => \@W7732,   'W7751'   => \@W7751,   'W7752'   => \@W7752 );

# Each Waveform card has a unique ID
# SY55/TG55 Waveform cards (W55XX) use the same ID as equivalent SY77/TG77 cards
my %waveid=(
    'RSC3001' => 11, 'RSC3002' => 12, 'RSC3003' => 15, 'RSC3004' => 16,
    'RSC3071' => 17, 'RSC3072' => 18, 'RSC3073' => 19, 'RSC3074' => 20,
    'W7701'   =>  3, 'W7702'   =>  2, 'W7704'   =>  7, 'W7705'   =>  0,
    'W7731'   =>  6, 'W7732'   => 10, 'W7751'   =>  4, 'W7752'   =>  9 );

# Inserted Wave Cards (default to empty slots)
my @wave_card=('', $wavecards[0], $wavecards[0], $wavecards[0]);

# Data cards
my @datacards=(' -- empty slot -- ', 'MCD32 Data Card', 'MCD64 Data Card: Bank 1', 'MCD64 Data Card: Bank 2');
my $data_card=$datacards[0];

# Initial waveform sources
my @wsources=('Preset', 'IntRAM');

# Rhythm Kits
my @rykit=('Preset', 'Internal');

my @int_kit=(); for (my $nr=1; $nr<=64; $nr++) { $int_kit[$nr-1]=(sprintf("%02d",$nr)).':UserRhyKit'; }

my @pre_kit=('01:Rock 1',     '02:Rock 2',     '03:Rock 3',     '04:Studio 1',   '05:Studio 2',   '06:Metal',
             '07:Pop 1',      '08:Pop 2',      '09:Country',    '10:LatinRock',  '11:LatinPerc',  '12:Brazil',
             '13:Funk',       '14:R&B 1',      '15:R&B 2',      '16:JazzBig',    '17:JazzSmall',  '18:JazzBrush',
             '19:Dance 1',    '20:Dance 2',    '21:House 1',    '22:House 2',    '23:Rap',        '24:MouthKit',
             '25:Hip Hop',    '26:World 1',    '27:World 2',    '28:Gated 1',    '29:Gated 2',    '30:Fusion 1',
             '31:Fusion 2',   '32:Reggae 1',   '33:Reggae 2',   '34:Techno 1',   '35:Techno 2',   '36:Analog 1',
             '37:Analog 2',   '38:Reverb',     '39:Stadium',    '40:SfxKit 1',   '41:SfxKit 2',   '42:G MIDI',
             '43:YAMAHA RX',  '44:Dry Zone 1', '45:Dry Zone 2', '46:RoomZone 1', '47:RoomZone 2', '48:RevZone 1',
             '49:RevZone 2',  '50:Kicks 1',    '51:Kicks 2',    '52:Kicks 3',    '53:Snares 1',   '54:Snares 2',
             '55:Snares 3',   '56:Toms 1',     '57:Toms 2',     '58:Toms 3',     '59:Cymbals 1',  '60:Cymbals 2',
             '61:Perc 1',     '62:Perc 2',     '63:SpecialFX1', '64:FX/ Stacks');

my %kithash=('Preset' => \@pre_kit, 'Internal' => \@int_kit, 'Card' => \@int_kit);

# array mapping MIDI note numbers 35-83 to notes B0-B4
my @note;
my @keys=('C ', 'C#', 'D ', 'D#', 'E ', 'F ', 'F#', 'G ', 'G#', 'A ', 'A#', 'B ');
$note[35]='B 0';
for (my $nnr=1; $nnr<=4; $nnr++) {
    for (my $ky=1; $ky<=12; $ky++) {
        push (@note, $keys[$ky-1].$nnr);
    }
}
my @notesl=@note[35..83];
my %noteshash; @noteshash{@notesl}=0..$#notesl;

# selected and available midi in/out devices
my $midi_outdev="";
my $midi_outdev_prev="";
my $midi_indev="";
my $midi_indev_prev="";
my @midi_indevs=MidiPortList('in');
my @midi_outdevs=MidiPortList('out');

# these widgets need to be global
my @elm_wave_entry;
my @wave_source_sel;
my $midiupload;
my $rymidiupload;
my $midiin;
my $midiout;
my $voice_dwn_sel;
my $bank_dwn_sel;
my $vcdwn_btn;

# default values for voice download frame
my $selected_bank="I-MX";
my $selected_voice=${voiceshash{$selected_bank}}[0];
my @banks_array=(sort(keys(%voiceshash)));

# down arrow bitmap for pulldown menu
my $darrow_bits=pack("b11"x10,
    "...........",
    ".111111111.",
    "...........",
    "...........",
    ".111111111.",
    "..1111111..",
    "...11111...",
    "....111....",
    ".....1.....",
    "...........");

# rhythm kit data variables
my $rywin;
my $kit_name;
my $ry_pbrange;
my @ry_trnote;
my @ry_bank_sel;
my @ry_bank;
my @ry_voice_sel;
my @ry_voice;
my @ry_att;
my @ry_mod;
my @ry_bal;
my @ry_flt;
my @ry_pan;
my @ry_dcy;
my @ry_vol;
my @ry_pbd;
my @ry_kyo;
# rhythm kit download frame
my $rybank_dwn_sel;
my $rykit_dwn_sel;
my $rykitdwn_btn;
my $selected_rybank='Preset';
my $selected_rykit=${kithash{$selected_rybank}}[0];
# default Rhythm Kit number (1-64)
my $dest_rynr=1;
# default MIDI channel for playing Rhythm Kit
my $ry_ch=1;
# banks hash with additional OFF bank for rhythm kits
my %rybankshash=(%bankshash, 'OFF'=>46);
my @OFF_voice=('01:- - - - - - - -');
my %ryvoiceshash=(%voiceshash, 'OFF'=>\@OFF_voice);
my @rybanks_array=(sort(keys(%ryvoiceshash)));

# initialise rhythm kit data variables with default values
NewRyKit();

# define voice data variables
my $voice_name;            my $volume;
my $balance;               my $pan;
my $pitch;                 my $decay;
my $cfilter_cutoff_freq;   my $vassign;
my $altgroup;              my $voutput;
my $indiv_level;           my $b44;
# Wave
my @elm_wave;              my @wave_source;
my @wave_dir;
# Lvel / Pan / Pitch
my @elm_level;             my @elm_pan;
my @elm_pitch;
# EG
my @eg_attack;             my @eg_decay;
my @eg_release;            my @eg_punch;
# Filter
my @filter_type;           my @filter_cutoff_frq;
my @filter_resonance;      my @filter_eg_rate;
my @filter_eg_level;
# LFO
my @lfo_destination;       my @lfo_wav_shape;
my @lfo_mod_speed;         my @lfo_delay;
my @lfo_phase;             my @lfo_mod_depth;
# Sensitivity
my @sens_level;            my @sens_pitch;
my @sens_eg;               my @sens_filter;
my @sens_modul;
# Pitch EG
my @pitch_eg_rate;         my @pitch_eg_lvl;
# Delay
my @delay_repetition;      my @del_first_note;
my @delay_time;            my @delay_lvl_offset;
my @delay_pch_offset;
# Velocity curve
my @elm_velcurve;

# default RM50 device number (1-16)
my $dev_nr=1;

# default destination voice number (1-128)
my $dest_vnr=1;

# initialise RM50 single voice sysex dump file
my $sysex_dump="\xF0\x43".chr($dev_nr-1)."\x7A\x01\x2ALM  0087VC"."\x00"x15 .chr($dest_vnr-1)."\x00"x144 ."\x00\xF7";

# initialise RM50 single rhythm kit sysex dump file
my $ry_syx_dump="\xF0\x43".chr($dev_nr-1)."\x7A\x03\x4CLM  0087KT"."\x00"x15 .chr($dest_rynr-1)."\x00"x434 ."\x00\xF7";

# initialise voice data variables with default values
newVoice();

# set up main program window
my $mw=MainWindow->new();
$mw->title("RM50 Manager - Voice Editor");
$mw->resizable(0,0);

$mw->fontCreate('title', -family=>'Sans', -weight=>'bold', -size=>9);

$mw->DefineBitmap('darrow'=>11,10,$darrow_bits);

# catch users pressing the window close button
$mw->protocol(WM_DELETE_WINDOW => \&exitProgam );

# default font
$mw->optionAdd('*font', 'Sans 10');

# for better looking menus
$mw->optionAdd('*Menu.activeBorderWidth', 1, 99);
$mw->optionAdd('*Menu.borderWidth', 1, 99);
$mw->optionAdd('*Menubutton.borderWidth', 1, 99);
$mw->optionAdd('*Optionmenu.borderWidth', 1, 99);
# set default listbox properties
$mw->optionAdd('*Listbox.borderWidth', 3, 99);
$mw->optionAdd('*Listbox.selectBorderWidth', 0, 99);
$mw->optionAdd('*Listbox.highlightThickness', 0, 99);
$mw->optionAdd('*Listbox.Relief', 'flat', 99);
$mw->optionAdd('*Listbox.Width', 0, 99);
$mw->optionAdd('*Listbox.Height', 10, 99);
# set default entry properties
$mw->optionAdd('*Entry.borderWidth', 1, 99);
$mw->optionAdd('*Entry.highlightThickness', 0, 99);
$mw->optionAdd('*Entry.disabledForeground','black',99);
$mw->optionAdd('*Entry.disabledBackground', $LCDbg,99);
# set default scrollbar properties
$mw->optionAdd('*Scrollbar.borderWidth', 1, 99);
$mw->optionAdd('*Scrollbar.highlightThickness', 0, 99);
if ($LINUX) {$mw->optionAdd('*Scrollbar.Width', 10, 99);}
# set default button properties
$mw->optionAdd('*Button.borderWidth', 1, 99);
$mw->optionAdd('*Checkbutton.borderWidth', 1, 99);
# set default canvas properties
$mw->optionAdd('*Canvas.highlightThickness', 0, 99);


# set up main frame with top menu bar, three tabs and a status bar
my $mf1;
topMenubar();
my $book = $mw->NoteBook(
    -borderwidth =>1,
    -ipadx       =>0
) -> pack(
    -side   => 'top',  -expand => 1, 
    -fill   => 'both', -anchor => 'nw'
);
StatusBar();

my @tab;
$tab[0] = $book->add('Tab0', -label=>'Common');
$tab[1] = $book->add('Tab1', -label=>'Element 1');
$tab[2] = $book->add('Tab2', -label=>'Element 2');

# initialise all frames
my @mf2; my @mf3; my @mf4; my @mf5;
my @mf6; my @mf7; my $mf10; my $mf11;
Common_Frame();  Settings_Frame();
LFO_Frame(1);    LFO_Frame(2);
Filter_Frame(1); Filter_Frame(2);
EG_Frame(1);     EG_Frame(2);
Sens_Frame(1);   Sens_Frame(2);
Delay_Frame(1);  Delay_Frame(2);
Misc_Frame(1);   Misc_Frame(2);

# assemble Element 1 tab
$mf7[1]->grid($mf2[1],$mf5[1], -sticky=>'nsew');
$mf6[1]->grid($mf3[1],$mf4[1], -sticky=>'nsew');

# assemble Element 2 tab
$mf7[2]->grid($mf2[2],$mf5[2], -sticky=>'nsew');
$mf6[2]->grid($mf3[2],$mf4[2], -sticky=>'nsew');

# read saved settings from config file
ReadSettings();


MainLoop;


# -----------
# Subroutines
# -----------

# set up to menu bar with keyboard bindings
sub topMenubar {
    $mf1=$mw->Frame(-borderwidth=>1, -relief=>'raised')->pack(-side=>'top', -expand=>1, -fill=>'x', -anchor=>'n');

    my $btn0=$mf1->Menubutton(-text=>'File', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'New',        -accelerator=>'Ctrl+N',  -command=>sub{ newVoice();
                                                                                        UpdateWSel(1, 0);
                                                                                        UpdateWSel(2, 0);
                                                                                      }         ],
                      ['command'=>'Open...',    -accelerator=>'Ctrl+O',  -command=>\&loadFile   ],
                      "-",
                      ['command'=>'Save',       -accelerator=>'Ctrl+S',  -command=>\&saveFile   ],
                      ['command'=>'Save As...', -accelerator=>'Ctrl+A',  -command=>\&saveasFile ],
                      "-",
                      ['command'=>'Quit',       -accelerator=>'Ctrl+Q',  -command=>\&exitProgam ]]
    )->pack(-side=>"left");
    $mw->bind($mw, "<Control-q>"=>\&exitProgam);
    $mw->bind($mw, "<Control-a>"=>\&saveasFile);
    $mw->bind($mw, "<Control-s>"=>\&saveFile);
    $mw->bind($mw, "<Control-o>"=>\&loadFile);
    $mw->bind($mw, "<Control-n>"=>sub{ newVoice(); UpdateWSel(1, 0); UpdateWSel(2, 0); });
    

    my $btn1=$mf1->Menubutton(-text=>'Edit', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'Rhythm Kit Editor...', -command=>sub{ if (! Exists($rywin)) { KitEditWin(); }
                                                                         else { $rywin->deiconify(); $rywin->raise(); }
                                                                       }            ],
                      "-",
                      ['command'=>'Save Settings',        -command=>\&SaveSettings ]]
    )->pack(-side=>"left");

    my $btn2=$mf1->Menubutton(-text=>'Help', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'About', -accelerator=>'Alt+A', -command=>\&About, -underline=>0]]
    )->pack(-side=>'left');
    $mw->bind($mw, "<Alt-a>"=>\&About);
}

# build the bottom status bar with current file name display and midi dump button
sub StatusBar {

    my $stb=$mw->Frame(
        -borderwidth  => 1,
        -relief       => 'raised'
    ) -> pack(
        -side => 'bottom', -expand => 1,
        -fill => 'both',   -anchor => 'sw'
    );

    my $file_display=$stb->Label(
        -anchor       => 'w',
        -relief       => 'sunken',
        -borderwidth  => 1,
        -width        => 82,
        -font         => 'Sans 9',
        -textvariable => \$filename
    )->pack(-side=>'left', -padx=>2, -pady=>2);

    $midiupload=$stb->Button(
        -text         => 'Upload via MIDI to RM50',
        -pady         => 2,
        -underline    => 0,
        -command      => \&SysexVceUpload
    )->pack(-side=>'right');
    $mw->bind($mw, "<Control-u>"=>\&SysexVceUpload);

    if ($midi_outdev ne '') { 
        $midiupload->configure(-state=>'active');
    } else {
        $midiupload->configure(-state=>'disabled');
    }
}

# Save settings to default config file
sub SaveSettings {
    if ($midi_indev ne '') { $cfg->param('MIDI_IN', "$midi_indev"); }
    if ($midi_outdev ne '') { $cfg->param('MIDI_OUT', "$midi_outdev"); }
    $cfg->param('RM50_Dev_Nr', $dev_nr);
    $cfg->param('Dest_Vce_Nr', $dest_vnr);
    $cfg->param('Wave_Card1', "$wave_card[1]");
    $cfg->param('Wave_Card2', "$wave_card[2]");
    $cfg->param('Wave_Card3', "$wave_card[3]");
    $cfg->param('Data_Card', "$data_card");
    $cfg->save('rm50_manager.ini') or Error(\$mw,$cfg->error());
}

# Read saved default settings from config file
sub ReadSettings {
    $cfg->read('rm50_manager.ini') or Error(\$mw,$cfg->error());
    # restore RM50 device number
    if ($cfg->param('RM50_Dev_Nr')             &&
        $cfg->param('RM50_Dev_Nr')=~/^[0-9]+$/ &&
        $cfg->param('RM50_Dev_Nr')>=1          &&
        $cfg->param('RM50_Dev_Nr')<=16) { $dev_nr=$cfg->param('RM50_Dev_Nr'); }
    # restore destination voice number
    if ($cfg->param('Dest_Vce_Nr')             &&
        $cfg->param('Dest_Vce_Nr')=~/^[0-9]+$/ &&
        $cfg->param('Dest_Vce_Nr')>=1          &&
        $cfg->param('RM50_Dev_Nr')<=128) { $dest_vnr=$cfg->param('Dest_Vce_Nr'); }
    # restore Waveform card config
    for (my $a=1; $a<=3; $a++) {
        if ($cfg->param("Wave_Card$a")) { $wave_card[$a]=$cfg->param("Wave_Card$a"); InsRemWavCard($a); }
    }
    # rescan MIDI devices for MIDI IN/OUT configuration
    my @midi_indevices=MidiPortList('in');
    my @midi_outdevices=MidiPortList('out');
    my $in_pre=0;
    my $out_pre=0;
    # restore MIDI IN config
    if ($cfg->param('MIDI_IN') && ($cfg->param('MIDI_IN') ne '')) {
        for (my $n=0; $n<@midi_indevices; $n++) {
            if ($midi_indevices[$n] eq $cfg->param('MIDI_IN')) {
                $midi_indev=$cfg->param('MIDI_IN');
                MidiConSetup('in');
                $in_pre=1;
                last;
            }
        }
        if ($in_pre == 0) {
            Error(\$mw,'Default MIDI IN device '. $cfg->param('MIDI_IN') .' not available, check connections.');
        }
    }
    # restore MIDI OUT config
    if ($cfg->param('MIDI_OUT') && ($cfg->param('MIDI_OUT') ne '')) {
        for (my $m=0; $m<@midi_outdevices; $m++) {
            if ($midi_outdevices[$m] eq $cfg->param('MIDI_OUT')) {
                $midi_outdev=$cfg->param('MIDI_OUT');
                MidiConSetup('out');
                $out_pre=1;
                last;
            }
        }
        if ($out_pre == 0) {
            Error(\$mw,'Default MIDI OUT device '. $cfg->param('MIDI_OUT') .' not available, check connections.');
        }
    }
    # restore data card config 
    if ($cfg->param('Data_Card')) { $data_card=$cfg->param('Data_Card'); InsRemDatCard(); }
}

# quit the program, ask for confirmation if unsaved changes
sub exitProgam {
    if ($modified == 1) {
        my $rtn=UnsavedChanges('Quit anyway?');
        if ($rtn eq 'Yes') {
            if ($WINDOWS && ($midi_outdev ne '')) { $midiOut->Close(); }
            exit;
        }
    } else {
        if ($WINDOWS && ($midi_outdev ne '')) { $midiOut->Close(); }
        exit;
    }
}

# load a rm50 voice sysex dump file
sub loadFile {
    my $rtn="";
    if ($modified == 1) {
        $rtn=UnsavedChanges('Open new file anyway?');
    }
    if ($rtn eq "Yes" || $modified == 0) {
        my $types=[ ['Sysex Files', ['.syx', '.SYX']], ['All Files', '*'] ];
        my $syx_file=$mw->getOpenFile(
            -defaultextension => '.syx',
            -filetypes        => $types,
            -title            => 'Open a RM50 Voice Dump Sysex file'
        );
        if ($syx_file && -r $syx_file) {
            open my $fh, '<', $syx_file;
            my $tmp_dump = do { local $/; <$fh> };
            close $fh;
            my $check=SysexValidate($tmp_dump);
            if ($check ne 'ok') {
                Error(\$mw,"Error while opening $syx_file\n\n$check");
            } else {
                $sysex_dump=$tmp_dump;
                SysexRead();
                $modified=0;
                $filename=$syx_file;
            }
        } elsif ($syx_file) {
            Error(\$mw,"Error: could not open $syx_file");
        }
    }
}

# load a rm50 rhythm kit sysex dump file
sub loadKit {
        my $types=[ ['Sysex Files', ['.syx', '.SYX']], ['All Files', '*'] ];
        my $syx_file=$rywin->getOpenFile(
            -defaultextension => '.syx',
            -filetypes        => $types,
            -title            => 'Open a RM50 Rhythm Kit Sysex file'
        );
        if ($syx_file && -r $syx_file) {
            open my $fh, '<', $syx_file;
            my $tmp_dump = do { local $/; <$fh> };
            close $fh;
            my $check=RySyxValidate(\$tmp_dump);
            if ($check ne 'ok') {
                Error(\$rywin,"Error while opening $syx_file\n\n$check");
            } else {
                RySyxRead(\$tmp_dump);
                $ryfilename=$syx_file;
            }
        } elsif ($syx_file) {
            Error(\$rywin,"Error: could not open $syx_file");
        }
}

# call as: UnsavedChanges($question), returns: Yes/No
sub UnsavedChanges {
    my $rtn=$mw->messageBox(
        -title   =>'Unsaved changes',
        -icon    => 'question',
        -message =>"There are unsaved changes that will be lost unless you save them first.\n\n$_[0]",
        -type    =>'YesNo',
        -default =>'No'
    );
    return $rtn;
}

# save edited voice to single voice sysex dump file
sub saveasFile {
    my $types=[ ['Sysex Files', ['.syx', '.SYX']], ['All Files', '*'] ];
        my $syx_file=$mw->getSaveFile(
            -defaultextension => ".syx",
            -filetypes        => $types,
            -title            => "Save as"
        );
    if ($syx_file) {
        my $fh;
        unless (open $fh, '>', $syx_file) {
            Error(\$mw,"Error: cannot save to file $syx_file\nCheck filesystem permissions.");
            return;
        }
        SysexWrite();
        my $chksum=chksumCalc(\$sysex_dump);
        substr($sysex_dump,176,1,chr($chksum));
        print $fh $sysex_dump;
        close $fh;
        $modified=0;
        $filename=$syx_file;
    }
}

# save edited rhythm kit to single rhythm kit sysex dump file
sub saveasKit {
    my $types=[ ['Sysex Files', ['.syx', '.SYX']], ['All Files', '*'] ];
        my $syx_file=$rywin->getSaveFile(
            -defaultextension => ".syx",
            -filetypes        => $types,
            -title            => "Save as"
        );
    if ($syx_file) {
        my $fh;
        unless (open $fh, '>', $syx_file) {
            Error(\$rywin,"Error: cannot save to file $syx_file\nCheck filesystem permissions.");
            return;
        }
        RySyxWrite(\$ry_syx_dump);
        my $chksum=chksumCalc(\$ry_syx_dump);
        substr($ry_syx_dump,466,1,chr($chksum));
        print $fh $ry_syx_dump;
        close $fh;
        $ryfilename=$syx_file;
    }
}

# save edited voice to previously opened single voice sysex dump file
sub saveFile {
    if ($filename ne '') {
        my $fh;
        unless (open $fh, '>', $filename) {
            Error(\$mw,"Error: cannot save to file $filename\nCheck filesystem permissions.");
            return;
        }
        SysexWrite();
        my $chksum=chksumCalc(\$sysex_dump);
        substr($sysex_dump,176,1,chr($chksum));
        print $fh $sysex_dump;
        close $fh;
        $modified=0;
    } else {
        saveasFile();
    }
}

# save edited rhythm kit to previously opened single voice sysex dump file
sub saveKit {
    if ($ryfilename ne '') {
        my $fh;
        unless (open $fh, '>', $ryfilename) {
            Error(\$rywin,"Error: cannot save to file $ryfilename\nCheck filesystem permissions.");
            return;
        }
        RySyxWrite(\$ry_syx_dump);
        my $chksum=chksumCalc(\$ry_syx_dump);
        substr($ry_syx_dump,466,1,chr($chksum));
        print $fh $ry_syx_dump;
        close $fh;
    } else {
        saveasKit();
    }
}

# upload current edited voice to RM50 via Sysex
sub SysexVceUpload {
    SysexWrite();
    my $chksum=chksumCalc(\$sysex_dump);
    substr($sysex_dump,176,1,chr($chksum));
    my $ddata=substr($sysex_dump,1,(length($sysex_dump)-2));
    if ($LINUX) {
        MIDI::ALSA::output( MIDI::ALSA::sysex( $dev_nr-1, $ddata, 0 ) );
        MIDI::ALSA::syncoutput();
    } elsif ($WINDOWS && ($midi_outdev ne '')) {
        # fixme: for some weird reason $ddata doesn't work, substr($ddata) is needed
        my $buf="\xF0". substr($ddata,0,length($ddata)) ."\xF7";
        my $midihdr = pack ("PLLLLPLL", $buf, length $buf, 0, 0, 0, undef, 0, 0);
        my $lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
        $midiOut->PrepareHeader($lpMidiOutHdr);
        $midiOut->LongMsg($lpMidiOutHdr);
        $midiOut->UnprepareHeader($lpMidiOutHdr);
    }
}

# upload current edited rhythm kit to RM50 via Sysex
sub SysexRyUpload {
    RySyxWrite(\$ry_syx_dump);
    my $chksum=chksumCalc(\$ry_syx_dump);
    substr($ry_syx_dump,466,1,chr($chksum));
    my $ddata=substr($ry_syx_dump,1,(length($ry_syx_dump)-2));
    if ($LINUX) {
        MIDI::ALSA::output( MIDI::ALSA::sysex( $dev_nr-1, $ddata, 0 ) );
        MIDI::ALSA::syncoutput();
    } elsif ($WINDOWS && ($midi_outdev ne '')) {
        # fixme: for some weird reason $ddata doesn't work, substr($ddata) is needed
        my $buf="\xF0". substr($ddata,0,length($ddata)) ."\xF7";
        my $midihdr = pack ("PLLLLPLL", $buf, length $buf, 0, 0, 0, undef, 0, 0);
        my $lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
        $midiOut->PrepareHeader($lpMidiOutHdr);
        $midiOut->LongMsg($lpMidiOutHdr);
        $midiOut->UnprepareHeader($lpMidiOutHdr);
    }
}

# 'About' information window
sub About {
    $mw->messageBox(
        -title   => 'About',
        -icon    => 'info',
        -message => "Yamaha\x{2122} RM50 Manager version $version\n
         \x{00A9} 2012 LinuxTECH.NET\n\nYamaha is a registered trademark of Yamaha Corporation.",
        -type    => 'Ok',
        -default => 'Ok'
    );
}

# Error popup window
sub Error {
    my $win=$_[0];
    my $msg=$_[1];
    ${$win}->messageBox(
        -title   =>'Error',
        -icon    => 'warning',
        -message =>"$msg",
        -type    =>'Ok',
        -default =>'Ok'
    );
}

# Converts a two byte substring (each byte limited to ASCII 0-9,A-F) at the given
# offset of the given sysex dump data reference and returns a decimal number between 0-255.
# Examples: 'FF' => 255  '7F' => 127  '00' => 0
# Invoke: Syx2Dec( \$dump, $offset )
sub Syx2Dec {
    return (hex(substr(${$_[0]},$_[1],2)));
}

sub Syx3Dec {
    return (hex(substr(${$_[0]},$_[1],3)));
}

# Converts a given decimal number between 0-255 into a two byte string containing
# the MSB and the LSB of the hex representation of the decimal number given and
# writes it at the given offset into the sysex dump data string provided as reference.
# Examples: 0 => '00'  127 => '7F'  255 => 'FF'
# Invoke: Dec2Syx( \$dump, $offset, $dec_value )
sub Dec2Syx {
    substr(${$_[0]},$_[1],2,sprintf("%02X",$_[2]));
}

sub Dec3Syx {
    substr(${$_[0]},$_[1],3,sprintf("%03X",$_[2]));
}

# subroutine that reads all rhythm kit settings from a sysex dump string
sub RySyxRead {
    # needs to be reference to dump string
    my $dmp=$_[0];

    $kit_name='';
    for(my $i = 32; $i < 52; $i+=2) {
        $kit_name=$kit_name.chr(Syx2Dec($dmp,$i));
    }

    $ry_pbrange  =      (Syx2Dec($dmp,52));

    $ry_trnote[1]=$notesl[(Syx2Dec($dmp,54))];
    $ry_trnote[2]=$notesl[(Syx2Dec($dmp,56))];
    $ry_trnote[3]=$notesl[(Syx2Dec($dmp,58))];
    $ry_trnote[4]=$notesl[(Syx2Dec($dmp,60))];
    $ry_trnote[5]=$notesl[(Syx2Dec($dmp,62))];
    $ry_trnote[6]=$notesl[(Syx2Dec($dmp,64))];

    for (my $elm=1; $elm<=49; $elm++) {
        my $e=(6*($elm-1));
        my $tmp=Syx2Dec($dmp,76+$e);
        $ry_mod[$elm]=    ($tmp %   2);
        $ry_bal[$elm]=int(($tmp %   4) /   2);
        $ry_flt[$elm]=int(($tmp %   8) /   4);
        $ry_pan[$elm]=int(($tmp %  16) /   8);
        $ry_dcy[$elm]=int(($tmp %  32) /  16);
        $ry_vol[$elm]=int(($tmp %  64) /  32);
        $ry_pbd[$elm]=int(($tmp % 128) /  64);
        $ry_kyo[$elm]=int(($tmp % 256) / 128);

        $ry_att[$elm][0]=int((Syx2Dec($dmp,78+$e)%256)/16);

        my %ryhashbanks= reverse %rybankshash;
        $ry_bank[$elm][0]=$ryhashbanks{((Syx2Dec($dmp,78+$e)%16)*2+int((Syx2Dec($dmp,80+$e)%256)/128))*2};
        if (exists $ryvoiceshash{$ry_bank[$elm][0]}) {
            $ry_voice[$elm][0]=${$ryvoiceshash{$ry_bank[$elm][0]}}[(Syx2Dec($dmp,80+$e)%128)];
        } else {
            Error(\$rywin,"Error: Voice 1 of note $notesl[$elm-1] requires a card in slot $ry_bank[$elm][0]. Setting voice to OFF.");
            $ry_bank[$elm][0]='OFF';
            $ry_voice[$elm][0]=${$ryvoiceshash{$ry_bank[$elm][0]}}[0];
        }

        # second voice for first 24 notes
        if ($elm<=24) {
            my $o=(4*($elm-1));
            $ry_att[$elm][1]=int((Syx2Dec($dmp,370+$o)%256)/16);
            $ry_bank[$elm][1]=$ryhashbanks{((Syx2Dec($dmp,370+$o)%16)*2+int((Syx2Dec($dmp,372+$o)%256)/128))*2};
            if (exists $ryvoiceshash{$ry_bank[$elm][1]}) {
                $ry_voice[$elm][1]=${$ryvoiceshash{$ry_bank[$elm][1]}}[(Syx2Dec($dmp,372+$o)%128)];
            } else {
                Error(\$rywin,"Error: Voice 2 of note $notesl[$elm-1] requires a card in slot $ry_bank[$elm][1]. Setting voice to OFF.");
                $ry_bank[$elm][1]='OFF';
                $ry_voice[$elm][1]=${$ryvoiceshash{$ry_bank[$elm][1]}}[0];
            }
        }
    }
}

# subroutine that writes all rhythm kit settings to a sysex dump string
sub  RySyxWrite {
    # needs to be reference to dump string
    my $dmp=$_[0];

    my $nam_len=length($kit_name);
    # pad kit name with spaces if less than 10 chars
    if ($nam_len<10) { $kit_name=$kit_name." "x(10-$nam_len); }
    for(my $i = 32; $i < 52; $i+=2) {
        Dec2Syx($dmp,$i, ord(substr($kit_name,(($i-32)/2),1)) );
    }

    # write current device number to sysex dump file
    substr(${$dmp},2,1,chr($dev_nr-1));
    # write current voice destination number to sysex dump file
    substr(${$dmp},31,1,chr($dest_rynr-1));

    Dec2Syx($dmp, 52, $ry_pbrange );

    Dec2Syx($dmp, 54, $noteshash{$ry_trnote[1]} );
    Dec2Syx($dmp, 56, $noteshash{$ry_trnote[2]} );
    Dec2Syx($dmp, 58, $noteshash{$ry_trnote[3]} );
    Dec2Syx($dmp, 60, $noteshash{$ry_trnote[4]} );
    Dec2Syx($dmp, 62, $noteshash{$ry_trnote[5]} );
    Dec2Syx($dmp, 64, $noteshash{$ry_trnote[6]} );

    for (my $elm=1; $elm<=49; $elm++) {
        my $e=(6*($elm-1));

        Dec2Syx($dmp, 76+$e, ( $ry_mod[$elm]     + ($ry_bal[$elm]* 2) + ($ry_flt[$elm]* 4) + ($ry_pan[$elm]*  8) +
                              ($ry_dcy[$elm]*16) + ($ry_vol[$elm]*32) + ($ry_pbd[$elm]*64) + ($ry_kyo[$elm]*128) ) );

        my $tmp_bank=($rybankshash{$ry_bank[$elm][0]}/2);
        my ($tmp_vce)=($ry_voice[$elm][0]=~/^(\d+):.*/);
        Dec2Syx($dmp, 78+$e, (($ry_att[$elm][0]*16) + int($tmp_bank/2)) );
        Dec2Syx($dmp, 80+$e, (($tmp_vce - 1) + ($tmp_bank % 2)*128) );

        # second voice for first 24 notes
        if ($elm<=24) {
            my $o=(4*($elm-1));
            my $tmp_bank2=($rybankshash{$ry_bank[$elm][1]}/2);
            my ($tmp_vce2)=($ry_voice[$elm][1]=~/^(\d+):.*/);
            Dec2Syx($dmp,370+$o, (($ry_att[$elm][1]*16) + int($tmp_bank2/2)) );
            Dec2Syx($dmp,372+$o, (($tmp_vce2 - 1) + ($tmp_bank2 % 2)*128) );
        }
    }
}

# subroutine that reads all voice settings from the sysex dump string
sub SysexRead {
    my $dmp=\$sysex_dump;

    $voice_name='';
    for(my $i = 50; $i < 66; $i+=2) {
        $voice_name=$voice_name.chr(Syx2Dec($dmp,$i));
    }

    # values: 0..127
    $volume             =    (Syx2Dec($dmp,32));
    # values: 0..64
    $pan                =    (Syx2Dec($dmp,34)-32);
    # values: 0..128
    $pitch              =    (Syx2Dec($dmp,36)-64);
    # values: 0..128
    $decay              =    (Syx2Dec($dmp,38)-64);
    # values: 0..128
    $cfilter_cutoff_freq=    (Syx2Dec($dmp,40)-64);
    # values: 0..128
    $balance            =    (Syx2Dec($dmp,42)-64);
    # unknown
    $b44                =    (Syx2Dec($dmp,44));
    # bits 0-2 - values: 0..6
    $voutput            =    (Syx2Dec($dmp,46)%8);
    # bits 4-6 - values: 0..7
    $altgroup           =int((Syx2Dec($dmp,46)%128)/16);
    # bits 0-5 - values: 0..63
    $indiv_level        =    (Syx2Dec($dmp,48)%64);
    # bits 6-7 - values: 0..3
    $vassign            = int(Syx2Dec($dmp,48)/64);

    for (my $elm = 1; $elm <= 2; $elm++) {
        my $e=(52*($elm-1));
        # bits 6-7 0..2 (Preset, Wave Card, Internal RAM)
        my $tmp                  =       int(Syx2Dec($dmp, 74+$e)/64);
        if    ($tmp==0) {$wave_source[$elm]=$wsources[0];}
        elsif ($tmp==2) {$wave_source[$elm]=$wsources[1];}
        elsif ($tmp==1) {
            my %idwave=reverse %waveid;
            my $idnr=Syx3Dec($dmp,66+(($elm-1)*3));
            my $card=$idwave{$idnr};
            if ($card && ($wave_card[1]=~/^$card:.*/ || $wave_card[2]=~/^$card:.*/ || $wave_card[3]=~/^$card:.*/)) {
                $wave_source[$elm]=$card;
                # for debugging purposes
                # print STDERR "Element [".$elm."] uses card [".$card."].\n";
            } elsif ($card) {
                $wave_source[$elm]=$card;
                Error(\$mw,"Error: card $card needed by Element $elm of this voice is not inserted, please insert it.");
            } else {
                Error(\$mw,"Error: card ID# $idnr for Element $elm of this voice is unknown. Using waveform from preset bank instead.");
            }
        }
        # values: 0..132 (Preset), 0..31 (Wave Card), 0..63 (Wave RAM), 255 off
        UpdateWSel($elm, Syx2Dec($dmp, 72+$e));
        # bits 0-5 values: 0..63
        $elm_level[$elm]         =          (Syx2Dec($dmp, 74+$e)%64);
        # values: 0..32 (16 = centre)
        $elm_pan[$elm]           =          (Syx2Dec($dmp, 76+$e)%64);
        # values: 78:0..72 80:0..99 => display values: -3600 to +3600
        $elm_pitch[$elm]         =        (((Syx2Dec($dmp, 78+$e)%128-36)*100)+Syx2Dec($dmp,80+$e)%128);
        # bit 6  values: 0..1
        $wave_dir[$elm]          =      int((Syx2Dec($dmp, 82+$e)%128)/64);
        # bits 0-5  values: 0..63
        $eg_attack[$elm]         =          (Syx2Dec($dmp, 82+$e)%64);
        # values: 0..63
        $eg_decay[$elm]          =          (Syx2Dec($dmp, 84+$e)%64);
        # values: 0..63
        $eg_release[$elm]        =          (Syx2Dec($dmp, 86+$e)%64);
        # bits 3-5  values: 0..7
        $eg_punch[$elm]          =      int((Syx2Dec($dmp, 88+$e)%64)/8);
        # bits 0-2  values: 0..4
        $filter_type[$elm]       =          (Syx2Dec($dmp, 88+$e)%8);
        # values: 0..127
        $filter_cutoff_frq[$elm] =          (Syx2Dec($dmp, 90+$e)%128);
        # values: 0..99
        $filter_resonance[$elm]  =          (Syx2Dec($dmp, 92+$e)%128);
        # values: 0..126 => display values: -63 to +63
        $filter_eg_level[$elm]   =          (Syx2Dec($dmp, 94+$e)%128-63);
        # values: 0..63
        $filter_eg_rate[$elm]    =          (Syx2Dec($dmp, 96+$e)%64);
        # bits 4-7  dump range: 15..9,0,1..7 => display values: -7 to +7
        $sens_level[$elm]        = ((int(int(Syx2Dec($dmp, 98+$e)/16)/8)*-2+1) * (int(Syx2Dec($dmp, 98+$e)/16)%8));
        # bits 0-3  dump range: 15..9,0,1..7 => display values: -7 to +7
        $sens_pitch[$elm]        =    ((int((Syx2Dec($dmp, 98+$e)%16)/8)*-2+1) *     (Syx2Dec($dmp, 98+$e)%8));
        # bits 4-7  dump range: 15..9,0,1..7 => display values: -7 to +7
        $sens_eg[$elm]           = ((int(int(Syx2Dec($dmp,100+$e)/16)/8)*-2+1) * (int(Syx2Dec($dmp,100+$e)/16)%8));
        # bits 0-3  dump range: 15..9,0,1..7 => display values: -7 to +7
        $sens_filter[$elm]       =    ((int((Syx2Dec($dmp,100+$e)%16)/8)*-2+1) *     (Syx2Dec($dmp,100+$e)%8));
        # bits 0-2  values: 0..7
        $sens_modul[$elm]        =          (Syx2Dec($dmp,102+$e)%8);
        # bits 4-6  values: 0..5
        $lfo_wav_shape[$elm]     =      int((Syx2Dec($dmp,102+$e)%128)/16);
        # values: 0..99
        $lfo_mod_speed[$elm]     =          (Syx2Dec($dmp,104+$e)%128);
        # values: 0..99
        $lfo_delay[$elm]         =          (Syx2Dec($dmp,106+$e)%128);
        # bits 0-5  values: 0..63
        $lfo_phase[$elm]         =          (Syx2Dec($dmp,108+$e)%64);
        # bits 6-7  values: 0..3
        $lfo_destination[$elm]   =       int(Syx2Dec($dmp,108+$e)/64);
        # values: 0..127
        $lfo_mod_depth[$elm]     =          (Syx2Dec($dmp,110+$e)%128);
        # values: 0..144 => display values: -72 to +72
        $pitch_eg_lvl[$elm]      =          (Syx2Dec($dmp,112+$e)-72);
        # values: 0..63
        $pitch_eg_rate[$elm]     =          (Syx2Dec($dmp,114+$e)%64);
        # bits 0-6  values: 0..127 => display values: 1-128
        $delay_time[$elm]        =          (Syx2Dec($dmp,116+$e)%128+1);
        # bit 7  values: 0..1
        $del_first_note[$elm]    =       int(Syx2Dec($dmp,116+$e)/128);
        # bits 5-7  dump range: 0..7 => display values: off,1-7
        $delay_repetition[$elm]  =       int(Syx2Dec($dmp,118+$e)/32);
        # bits 0-4  dump range: 17..31,0,1..15 => display values: -15 to +15
        $delay_lvl_offset[$elm]  =    ((int((Syx2Dec($dmp,118+$e)%32)/16)*-16)+(Syx2Dec($dmp,118+$e)%16));
        # dump range: 136..255,0,0..120 => display values: -12.0 to +12.0
        $delay_pch_offset[$elm]  =    (((int(Syx2Dec($dmp,120+$e)/128)*-128) + (Syx2Dec($dmp,120+$e)%128))/10);
        # values: 0..11
        $elm_velcurve[$elm]      = $vlcurves[Syx2Dec($dmp,122+$e)%16];
    }
}

# subroutine that writes all current voice settings to the sysex dump string
sub SysexWrite {
    my $dmp=\$sysex_dump;
    my $nam_len=length($voice_name);
    # pad voice name with spaces if less than 8 chars
    if ($nam_len<8) { $voice_name=$voice_name." "x(8-$nam_len); }
    for(my $i = 50; $i < 66; $i+=2) {
        Dec2Syx($dmp,$i, ord(substr($voice_name,(($i-50)/2),1)) );
    }
    # write current device number to sysex dump file
    substr($sysex_dump,2,1,chr($dev_nr-1));
    # write current voice destination number to sysex dump file
    substr($sysex_dump,31,1,chr($dest_vnr-1));
    Dec2Syx($dmp, 32, $volume );
    Dec2Syx($dmp, 34, ($pan + 32 ));
    Dec2Syx($dmp, 36, ($pitch + 64 ));
    Dec2Syx($dmp, 38, ($decay + 64 ));
    Dec2Syx($dmp, 40, ($cfilter_cutoff_freq + 64 ));
    Dec2Syx($dmp, 42, ($balance + 64 ));
    Dec2Syx($dmp, 44, $b44);
    Dec2Syx($dmp, 46, (($altgroup *16) + $voutput ));
    Dec2Syx($dmp, 48, (($vassign  *64) + $indiv_level ));

    for (my $elm = 1; $elm <= 2; $elm++) {
        my $e=(52*($elm-1));
        my ($wavnr)=($elm_wave[$elm]=~/^(\d+):.*/);
        Dec2Syx($dmp, 72+$e, ($wavnr-1) );
        my $tmp=0;
        if ($wave_source[$elm] eq $wsources[0]) {
            $tmp=0;
            Dec3Syx($dmp, 66+(($elm-1)*3), 4095 );
        } elsif ($wave_source[$elm] eq $wsources[1]) {
            $tmp=2;
            Dec3Syx($dmp, 66+(($elm-1)*3), 4095 );
        } else  {
            $tmp=1;
            Dec3Syx($dmp, 66+(($elm-1)*3), $waveid{$wave_source[$elm]});
        }
        Dec2Syx($dmp, 74+$e, ($tmp *64) + $elm_level[$elm] );
        Dec2Syx($dmp, 76+$e, $elm_pan[$elm] );
        Dec2Syx($dmp, 78+$e, (int($elm_pitch[$elm]/100)+36) );
        Dec2Syx($dmp, 80+$e, abs($elm_pitch[$elm]%100) );
        Dec2Syx($dmp, 82+$e, ($wave_dir[$elm] *64) + $eg_attack[$elm] );
        Dec2Syx($dmp, 84+$e, $eg_decay[$elm] );
        Dec2Syx($dmp, 86+$e, $eg_release[$elm] );
        Dec2Syx($dmp, 88+$e, ($eg_punch[$elm] *8) + $filter_type[$elm] );
        Dec2Syx($dmp, 90+$e, $filter_cutoff_frq[$elm] );
        Dec2Syx($dmp, 92+$e, $filter_resonance[$elm] );
        Dec2Syx($dmp, 94+$e, ($filter_eg_level[$elm] +63) );
        Dec2Syx($dmp, 96+$e, $filter_eg_rate[$elm] );
        Dec2Syx($dmp, 98+$e, ( (abs((int($sens_level[$elm] /($sens_level[$elm] +0.1))*8) - $sens_level[$elm] ) *16)
                             + (abs((int($sens_pitch[$elm] /($sens_pitch[$elm] +0.1))*8) - $sens_pitch[$elm] )    ) ) );
        Dec2Syx($dmp,100+$e, ( (abs((int($sens_eg[$elm]    /($sens_eg[$elm]    +0.1))*8) - $sens_eg[$elm]    ) *16)
                             + (abs((int($sens_filter[$elm]/($sens_filter[$elm]+0.1))*8) - $sens_filter[$elm])    ) ) );
        Dec2Syx($dmp,102+$e, ($lfo_wav_shape[$elm] *16) + $sens_modul[$elm] );
        Dec2Syx($dmp,104+$e, $lfo_mod_speed[$elm] );
        Dec2Syx($dmp,106+$e, $lfo_delay[$elm] );
        Dec2Syx($dmp,108+$e, ($lfo_destination[$elm] *64) + $lfo_phase[$elm] );
        Dec2Syx($dmp,110+$e, $lfo_mod_depth[$elm] );
        Dec2Syx($dmp,112+$e, ($pitch_eg_lvl[$elm] +72) );
        Dec2Syx($dmp,114+$e, $pitch_eg_rate[$elm] );
        Dec2Syx($dmp,116+$e, ($del_first_note[$elm] *128) + ($delay_time[$elm] -1) );
        Dec2Syx($dmp,118+$e, (($delay_repetition[$elm] *32)
                      + (abs((int($delay_lvl_offset[$elm] /($delay_lvl_offset[$elm]+ 0.1))*-32)  - $delay_lvl_offset[$elm])) ) );
        Dec2Syx($dmp,120+$e, (abs((int($delay_pch_offset[$elm] /($delay_pch_offset[$elm]+ 0.01))*-256) - $delay_pch_offset[$elm])*10) );
        my ($velcnr)=($elm_velcurve[$elm]=~/^(\d+):.*/);
        Dec2Syx($dmp,122+$e, ($velcnr-1) );
    }
}

# initialise all voice data with default values
sub newVoice {
    $voice_name          = 'Unnamed ';
    $volume              = 127;
    $balance             = 0;
    $pan                 = 0;
    $pitch               = 0;
    $decay               = 0;
    $cfilter_cutoff_freq = 0;
    $b44                 = 63;
    $vassign             = 0;
    $altgroup            = 0;
    $voutput             = 0;
    $indiv_level         = 63;
    for (my $elm = 1; $elm <= 2; $elm++) {
        $wave_source[$elm] = 'Preset';
        $elm_wave[$elm]  = ${$wavehash{$wave_source[$elm]}}[0];
        $wave_dir[$elm]  = 0;
        $elm_level[$elm] = 63;
        $elm_pan[$elm]   = 16;
        $elm_pitch[$elm] = 0;
        $eg_attack[$elm]  = 0;
        $eg_decay[$elm]   = 63;
        $eg_release[$elm] = 0;
        $eg_punch[$elm]   = 0;
        $filter_type[$elm]       = 0;
        $filter_cutoff_frq[$elm] = 127;
        $filter_resonance[$elm]  = 0;
        $filter_eg_rate[$elm]    = 0;
        $filter_eg_level[$elm]   = 0;
        $lfo_destination[$elm] = 0;
        $lfo_wav_shape[$elm]   = 0;
        $lfo_mod_speed[$elm]   = 0;
        $lfo_delay[$elm]       = 0;
        $lfo_phase[$elm]       = 0;
        $lfo_mod_depth[$elm]   = 0;
        $sens_level[$elm]   = 0;
        $sens_pitch[$elm]   = 0;
        $sens_eg[$elm]      = 0;
        $sens_filter[$elm]  = 0;
        $sens_modul[$elm]   = 0;
        $pitch_eg_rate[$elm] = 0;
        $pitch_eg_lvl[$elm]  = 0;
        $delay_repetition[$elm] = 0;
        $del_first_note[$elm]   = 0;
        $delay_time[$elm]       = 1;
        $delay_lvl_offset[$elm] = 0;
        $delay_pch_offset[$elm] = 0;
        $elm_velcurve[$elm] = '1:Linear';
    }
    $modified=0;
    $filename='';
}

# initialise rhythm kit
sub NewRyKit {
    $ryfilename='';
    $kit_name='Unnamed   ';
    $ry_pbrange=0;

    $ry_trnote[1]='C 1';
    $ry_trnote[2]='D 1';
    $ry_trnote[3]='D 2';
    $ry_trnote[4]='B 1';
    $ry_trnote[5]='G 1';
    $ry_trnote[6]='F 1';

    for (my $a=1; $a<=49; $a++) {
        my $end;
        if ($a<=24) { $end=1; } else { $end=0; }
        for (my $v=0; $v<=$end; $v++) {
            $ry_bank[$a][$v]='OFF';
            $ry_voice[$a][$v]=${$ryvoiceshash{$ry_bank[$a][$v]}}[0];
            $ry_att[$a][$v]='0';
        }
        $ry_mod[$a]='0';
        $ry_bal[$a]='0';
        $ry_flt[$a]='0';
        $ry_pan[$a]='0';
        $ry_dcy[$a]='0';
        $ry_vol[$a]='0';
        $ry_pbd[$a]='0';
        $ry_kyo[$a]='0';
    }
}

# check that the sysex dump is a valid RM50 single voice dump
sub SysexValidate {
    my $tmp_dump=$_[0];
    # check length
    my $dump_len=length($tmp_dump);
    $dump_len==178 or return "incorrect sysex length ($dump_len bytes)";
    # check correct header, footer and valid content
    $tmp_dump=~/^\xF0\x43[\x00-\x0F]\x7A\x01\x2ALM  0087VC\x00{15}[\x00-\x7F]{146}\xF7$/ or return "invalid sysex data";
    # calculate checksum
    my $chksum=chksumCalc(\$tmp_dump);
    # expected checksum
    my $expsum=(ord(substr($tmp_dump,176,1)));
    # compare
    ($chksum == $expsum) or return "incorrect sysex checksum";
    return "ok";
}

# check that the sysex dump is a valid RM50 single rhythm kit dump
# To invoke: RySyxValidate(\$dump)
sub RySyxValidate {
    my $ref_dump=$_[0];
    # check length
    my $dump_len=length(${$ref_dump});
    $dump_len==468 or return "incorrect sysex length ($dump_len bytes)";
    # check correct header, footer and valid content
    ${$ref_dump}=~/^\xF0\x43[\x00-\x0F]\x7A\x03\x4CLM  0087KT\x00{15}[\x00-\x7F]{436}\xF7$/ or return "invalid sysex data";
    # calculate checksum
    my $chksum=chksumCalc($ref_dump);
    # expected checksum
    my $expsum=(ord(substr(${$ref_dump},466,1)));
    # compare
    ($chksum == $expsum) or return "incorrect sysex checksum";
    return "ok";
}

# calculate sysex data checksum
# To invoke: chksumCalc(\$dump)
sub chksumCalc {
    my $ref_dump=$_[0];
    my $chksum=0;
    for (my $b=6; $b<(length(${$ref_dump})-2); $b++) {
        $chksum+=ord(substr(${$ref_dump},$b,1));
    }
    $chksum=(-$chksum & 0x7f);
    return $chksum;
}

# Update wave form selection pulldown list and reset selected voice
sub UpdateWSel {
    my $elm=$_[0];
    my $vce=$_[1];
    $elm_wave_entry[$elm]->delete( 0, "end" );
    $elm_wave_entry[$elm]->insert("end", $_) for (@{$wavehash{$wave_source[$elm]}});
    $elm_wave_entry[$elm]->configure(-listheight=>min((scalar @{$wavehash{$wave_source[$elm]}})+1,10) );
    if ($vce == 255) {
        $elm_wave[$elm]="256:--off---";
    } else {
        $elm_wave[$elm]=${$wavehash{$wave_source[$elm]}}[$vce];
    }
}

# send parameter change message to RM50 to update wave source and wave number
sub SendWvChMsg {
    my $elm=$_[0];
    my ($wavnr)=($elm_wave[$elm]=~/^(\d+):.*/);
    my $tmp=0;
    if    ($wave_source[$elm] eq $wsources[0])  { $tmp=0; }
    elsif ($wave_source[$elm] eq $wsources[1])  { $tmp=64; }
    elsif ($wave_card[1]=~/^$wave_source[$elm]:.*/) { $tmp=32; }
    elsif ($wave_card[2]=~/^$wave_source[$elm]:.*/) { $tmp=40; }
    elsif ($wave_card[3]=~/^$wave_source[$elm]:.*/) { $tmp=48; }
    else { Error(\$mw,"Error: waveform card $wave_source[$elm] used by Element $elm not inserted!\n\nPlease insert card into one of the slots."); }
    SendPaChMsg($elm+1,0,(int(($wavnr-1)/128)+$tmp),($wavnr-1)%128);
}

# send parameter change message to RM50 to update voice and bank numbers of rhythm kits
sub SendVcChMsg {
    my $elm=$_[0]; # 1..49
    my $vnr=$_[1]; # 0,1
    my $bnk=($rybankshash{$ry_bank[$elm][$vnr]})/2;
    my ($vce)=($ry_voice[$elm][$vnr]=~/^(\d+):.*/);
    SendRyChMsg($elm,($vnr*10),$bnk,$vce-1);
}

# only for testing purposes
sub Callbk {
    print "---\n";
    print "callback args  = @_\n";
#    print "\$Tk::event     = $Tk::event\n";
#    print "\$Tk::widget    = $Tk::widget\n";
#    print "\$Tk::event->W  = ". $Tk::event->W ."\n";
    $modified=1;
}

# send voice parameter change message (real time sysex) to RM50
sub SendPaChMsg {
    SendGenPaChMsg(3, 6, ($dest_vnr-1), $_[0], $_[1], $_[2], $_[3]);
}

sub SendRyChMsg {
    SendGenPaChMsg(2, 1, ($dest_rynr-1), $_[0], $_[1], $_[2], $_[3]);
}

# send generic parameter change message (real time sysex) to RM50
sub SendGenPaChMsg {
    my $pgroup=chr($_[0]);
    my $memory=chr($_[1]);
    my $number=chr($_[2]);
    my $parm_1=chr($_[3]);
    my $parm_2=chr($_[4]);
    my $val_hi=chr($_[5]);
    my $val_lo=chr($_[6]);
    my $ddata="\x43".chr($dev_nr-1+16)."\x30".$pgroup.$memory.$number.$parm_1.$parm_2.$val_hi.$val_lo;
    if ($LINUX) {
        MIDI::ALSA::output( MIDI::ALSA::sysex( $dev_nr-1, $ddata, 0 ) );
    } elsif ($WINDOWS && ($midi_outdev ne '')) {
        my $buf="\xF0".$ddata."\xF7";
        my $midihdr = pack ("PLLLLPLL", $buf, length $buf, 0, 0, 0, undef, 0, 0);
        my $lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
        $midiOut->PrepareHeader($lpMidiOutHdr);
        $midiOut->LongMsg($lpMidiOutHdr);
        $midiOut->UnprepareHeader($lpMidiOutHdr);
    }
}

# Play a Note via MIDI (send 'note on' or 'note off' event)
sub PlayMidiNote {
    my $ch=$_[0]; # midi channel 0-15
    my $nt=$_[1]; # midi note 0-127
    my $vl=$_[2]; # note velocity 0-127
    my $oo=$_[3]; # note on (1) or note off (0)
    if ($LINUX) {
        if ($oo) {
            MIDI::ALSA::output(MIDI::ALSA::noteonevent($ch,$nt,$vl));
        } else {
            MIDI::ALSA::output(MIDI::ALSA::noteoffevent($ch,$nt,$vl));
        }
    } elsif ($WINDOWS && ($midi_outdev ne '')) {
        my $msg=($vl*65536)+($nt*256)+(128+$ch+($oo*16));
        $midiOut->ShortMsg($msg);
    }
}

# do all updates required when a wave card is removed or inserted
sub InsRemWavCard {
    my $cardnr=$_[0];
    # refresh elements wave bank list and reset selected wave if from removed card
    for (my $elm=1; $elm<=2; $elm++) {
        $wave_source_sel[$elm]->delete( 2, "end" );
        my $flag=0; # used to check if card used in voice has been removed
        my $ct=0;   # counter to dynamically adapt listheight to nr of cards
        for (my $n=1; $n<=3; $n++) {
            my ($sel)=($wave_card[$n]=~/^([a-z,A-Z,0-9]+):.*/);
            if ($sel) {
                $ct++; $wave_source_sel[$elm]->insert("end", $sel);
                if ($sel eq $wave_source[$elm]) {$flag=1;}
            }
        }
        $wave_source_sel[$elm]->configure(-listheight=>(3+$ct));
        if (($flag == 0) && ($wave_source[$elm]!~/Preset|IntRAM/)) {
            $wave_source[$elm]=$wsources[0];
            UpdateWSel($elm, 0);
        }
    }
    # refresh download bank list and rhythm kit bank list adding/removing wave slots
    my ($card)=$wave_card[$cardnr]=~/^([a-z,A-Z,0-9]+):.*/;

    if ($wave_card[$cardnr] eq ' -- empty slot -- ') {
        delete $voiceshash{"W-S$cardnr"};
        delete $ryvoiceshash{"W-S$cardnr"};
        if ($selected_bank eq "W-S$cardnr") {
            $selected_bank="I-MX";
            RefreshVceDwnList();
        }
    } elsif ($wave_card[$cardnr]=~/^[a-z,A-Z,0-9]+:.*/) {
        %voiceshash=(%voiceshash, "W-S$cardnr"=>$wvevcehash{$card});
        %ryvoiceshash=(%ryvoiceshash, "W-S$cardnr"=>$wvevcehash{$card});
        if ($selected_bank eq "W-S$cardnr") {
            RefreshVceDwnList();
        }
    }
    RefreshBnkDwnList();
}

# called when Data Card selection is changed
sub InsRemDatCard { 
    # no data card inserted
    if ($data_card eq $datacards[0]) {
        delete @voiceshash{keys %crdvcehash};
        delete @ryvoiceshash{keys %crdvcehash};
        RefreshBnkDwnList();
        if ($selected_bank=~/^C-\w\w$/) {
            $selected_bank="I-MX";
            RefreshVceDwnList();
        }
        splice(@rykit,2,1);
        $selected_rybank=$rykit[0];
        if (Exists($rywin)) { RefreshKitBnkDwnList(); RefreshKitDwnList(); }
    }
    # MCD32 data card inserted (only 1 bank)
    elsif ($data_card eq $datacards[1]) {
        %voiceshash=(%voiceshash, %crdvcehash);
        %ryvoiceshash=(%ryvoiceshash, %crdvcehash);
        RefreshBnkDwnList();
        $rykit[2]='Card';
        if (Exists($rywin)) { RefreshKitBnkDwnList(); RefreshKitDwnList(); }
    }
    # MCD64 data card inserted using bank 1
    elsif ($data_card eq $datacards[2]) {
        SendGenPaChMsg(4, 0, 0, 6, 7, 0, 0);
        %voiceshash=(%voiceshash, %crdvcehash);
        %ryvoiceshash=(%ryvoiceshash, %crdvcehash);
        RefreshBnkDwnList();
        $rykit[2]='Card';
        if (Exists($rywin)) { RefreshKitBnkDwnList(); RefreshKitDwnList(); }
    }
    # MCD64 data card inserted using bank 2
    elsif ($data_card eq $datacards[3]) {
        SendGenPaChMsg(4, 0, 0, 6, 7, 0, 1);
        %voiceshash=(%voiceshash, %crdvcehash);
        %ryvoiceshash=(%ryvoiceshash, %crdvcehash);
        RefreshBnkDwnList();
        $rykit[2]='Card';
        if (Exists($rywin)) { RefreshKitBnkDwnList(); RefreshKitDwnList(); }
    }
}

sub RefreshBnkDwnList {
    @banks_array=(sort(keys(%voiceshash)));
    $bank_dwn_sel->delete( 0, "end" );
    $bank_dwn_sel->insert("end", $_) for (@banks_array);
}

sub RefreshKitBnkDwnList {
    $rybank_dwn_sel->delete( 0, "end" );
    $rybank_dwn_sel->insert("end", $_) for (@rykit);
}

sub RefreshVceDwnList { 
    $voice_dwn_sel->delete( 0, "end" );
    $voice_dwn_sel->insert("end", $_) for (@{$voiceshash{$selected_bank}});
    $selected_voice=${$voiceshash{$selected_bank}}[0];
}

sub RefreshKitDwnList {
    $rykit_dwn_sel->delete( 0, "end" );
    $rykit_dwn_sel->insert("end", $_) for (@{$kithash{$selected_rybank}});
    $selected_rykit=${$kithash{$selected_rybank}}[0];
}

# create an array of available midi ports
sub MidiPortList {
    my $dir=$_[0];
    my @portlist;
    if ($LINUX) {
        my %clients = MIDI::ALSA::listclients();
        my %portnrs = MIDI::ALSA::listnumports();
        my $tmp=0;
        while (my ($key, $value) = each(%clients)){
            if ($key>15 && $key<128) {
                for (my $i=0; $i<($portnrs{$key}); $i++) {
                    $portlist[$tmp]=$value.":".$i;
                    $tmp++;
                }
            }
        }
    } elsif ($WINDOWS) {
        if ($dir eq 'in') {
            my $iNumDevs=$midi->InGetNumDevs();
            for (my $i=0; $i<$iNumDevs; $i++) {
                my $cap=$midi->InGetDevCaps($i);
                $portlist[$i]=$$cap{szPname};
            }
        } elsif ($dir eq 'out') {
            my $oNumDevs=$midi->OutGetNumDevs();
            for (my $o=0; $o<$oNumDevs; $o++) {
                my $cap=$midi->OutGetDevCaps($o);
                $portlist[$o]=$$cap{szPname};
            }
        }
    }
    return @portlist;
}

# set up a new midi connection and drop the previous one
sub MidiConSetup {
    my $dir=$_[0];
    if ($LINUX) {
        MIDI::ALSA::stop();
        if ($dir eq 'out') {
            if ($midi_outdev_prev ne '') {
                MIDI::ALSA::disconnectto(1,"$midi_outdev_prev");
            }
            $midi_outdev_prev=$midi_outdev;
            MIDI::ALSA::connectto(1,"$midi_outdev");
        } elsif ($dir eq 'in') {
            if ($midi_indev_prev ne '') {
                MIDI::ALSA::disconnectfrom(0,"$midi_indev_prev");
            }
            $midi_indev_prev=$midi_indev;
            MIDI::ALSA::connectfrom(0,"$midi_indev");
        }
        MIDI::ALSA::start();
    } elsif ($WINDOWS) {
        if ($dir eq 'out') {
            if ($midi_outdev_prev ne '') {
                $midiOut->Close();
            }
            $midi_outdev_prev=$midi_outdev;
            my $dev=$midi->OutGetDevNum($midi_outdev);
            $midiOut=new Win32API::MIDI::Out($dev);
        } elsif ($dir eq 'in') {
            # add Windows specific code here
        }
    }
    if (($midi_indev ne '') && ($midi_outdev ne '')) {
        $vcdwn_btn->configure(-state=>'active');
        if (Exists($rywin)) { $rykitdwn_btn->configure(-state=>'active'); }
    } else {
        $vcdwn_btn->configure(-state=>'disabled');
        if (Exists($rywin)) { $rykitdwn_btn->configure(-state=>'disabled'); }
    }
    if ($midi_outdev ne '') {
        $midiupload->configure(-state=>'active');
        if (Exists($rywin)) { $rymidiupload->configure(-state=>'active'); }
    } else {
        $midiupload->configure(-state=>'disabled');
        if (Exists($rywin)) { $rymidiupload->configure(-state=>'disabled'); }
    }
}

# request and receive a sysex dump from the RM50
sub RM50toPCSyxDmp {
    # dump request type
    my $type=$_[0];
    # source voice or kit bank number
    my $sbank=$_[1];
    # source voice or kit number
    my $snr=$_[2];
    #debug output
    #print STDERR "type: [$type] bank: [$sbank] voice: [$snr]\n";
    # Yamaha RM50 sysex bulk dump request strings
    my $header='C'.chr($dev_nr-1+32);
    my $snglvcdmp='zLM  0087VC'."\x00"x12 .chr($sbank).chr($snr)."\x00".chr($dest_vnr-1);
    my $snglktdmp='zLM  0087KT'."\x00"x12 .chr($sbank).chr($snr)."\x00".chr($dest_vnr-1);
    my @req_strg = (
        [$header.'~LM  0087ML','channel setup bulk dump'],
        [$header.'~LM  0087SY','system setup bulk dump'],
        [$header.'~LM  0087PC','program change table bulk dump'],
        [$header.'~LM  0087VI','internal voice bulk dump'],
        [$header.'~LM  0087VW','wave card voice bulk dump'],
        [$header.'~LM  0087EP','variation voice bulk dump'],
        [$header.'~LM  0087KI','internal kit bulk dump'],
        [$header.$snglvcdmp,'single voice dump'],
        [$header.$snglktdmp,'single kit dump']
    );
    # send bulk dump request to RM50 and receive dump
    my $tmp_dump='';
    if ($LINUX) {
        MIDI::ALSA::output(MIDI::ALSA::sysex($dev_nr-1, $req_strg[$type][0], 0));
        while (1) {
            # read next ALSA input event
            my @alsaevent=MIDI::ALSA::input();
            # if the input connection has disappeared then exit
            if ( $alsaevent[0] == SND_SEQ_EVENT_PORT_UNSUBSCRIBED() ) {
                Error(\$mw,"Error: MIDI connection dropped.");
                return '';
            }
            # if we have received a sysex input event then do this
            elsif ( $alsaevent[0] == SND_SEQ_EVENT_SYSEX() ) {
                # save event data array
                my @data=@{$alsaevent[7]};
                # append sysex data chunk to $sysex_dump
                $tmp_dump=$tmp_dump.$data[0];
                # if last byte is F7 then sysex dump is complete
                if ( substr($data[0],-1) eq chr(247) ) {
                    last;
                }
            }
        }
    } elsif ($WINDOWS) {
        # add Windows specific code here
    }
    return $tmp_dump;
}

# request, receive and validate a single voice dump
sub RcvSnglVceDmp {
    my $sbank=$_[0];
    my $snr=$_[1];
    my $tmp_dump=RM50toPCSyxDmp(7, $sbank, $snr);
    my $result=SysexValidate($tmp_dump);
        if ($result eq 'ok') {
            $sysex_dump=$tmp_dump;
            SysexRead();
            $modified=0;
            $filename='';
            return 0;
        } else {
            Error(\$mw,"Error: $result");
            return 1;
        }
}

# request, receive and validate a single kit dump
sub RcvSnglKitDmp {
    my $sbank=$_[0];
    my $snr=$_[1];
    my $tmp_dump=RM50toPCSyxDmp(8, $sbank, $snr);
    my $result=RySyxValidate(\$tmp_dump);
        if ($result eq 'ok') {
            RySyxRead(\$tmp_dump);
            $ryfilename='';
            if ($sbank == 2) { $dest_rynr=$snr+1; }
            return 0;
        } else {
            Error(\$rywin,"Error: $result");
            return 1;
        }
}

# Refresh a rhythm kit editor voices pulldown list
sub RefreshVceList {
    my $a=$_[0];
    my $v=$_[1];
    my $reset=$_[2];
    $ry_voice_sel[$a][$v]->delete( 0, "end" );
    if (exists $ryvoiceshash{$ry_bank[$a][$v]}) {
        $ry_voice_sel[$a][$v]->insert("end", $_) for (@{$ryvoiceshash{$ry_bank[$a][$v]}});
        if ($reset) {
            $ry_voice[$a][$v]=${$ryvoiceshash{$ry_bank[$a][$v]}}[0];
            SendVcChMsg($a, $v);
        }
    }
}

# Refresh a rhythm kit editor banks pulldown list
sub RefreshBnkList {
    my $a=$_[0];
    my $v=$_[1];
    
    @rybanks_array=(sort(keys(%ryvoiceshash)));
    $ry_bank_sel[$a][$v]->delete( 0, "end" );
    $ry_bank_sel[$a][$v]->insert("end", $_) for (@rybanks_array);
}

#-------------------------------------------------------------------------------------------------------------------------
# Rhythm Kit Editor Window

sub KitEditWin {

    $rywin=$mw->Toplevel();
    $rywin->resizable(0,1);
    $rywin->minsize(480,480);
    $rywin->title('RM50 Manager - Rhythm Kit Editor');

    # Top Menubar
    my $mb=$rywin->Frame(-borderwidth=>1, -relief=>'raised'
    )->pack(-anchor=>'n', -fill=>'x');

    $mb->Menubutton(-text=>'File', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'New',        -accelerator=>'Ctrl+N',  -command=>sub{ NewRyKit(); } ],
                      ['command'=>'Open...',    -accelerator=>'Ctrl+O',  -command=>\&loadKit   ],
                      "-",
                      ['command'=>'Save',       -accelerator=>'Ctrl+S',  -command=>\&saveKit   ],
                      ['command'=>'Save As...', -accelerator=>'Ctrl+A',  -command=>\&saveasKit ],
                      "-",
                      ['command'=>'Close',       -accelerator=>'Ctrl+C',  -command=>[$rywin=>'destroy'] ]]
    )->pack(-side=>"left");

    my $fb=$rywin->Frame(
    )->pack(-anchor=>'n', -fill=>'x');

    $fb->Button(
        -font         => 'Sans 9',
        -text         => 'Ch Setup',
        -pady         => 0,
        -command      => sub{ SendGenPaChMsg(1,0,0,$ry_ch-1,0,0,0);
                              SendGenPaChMsg(1,0,0,$ry_ch-1,1,1,$dest_rynr-1); }
    )->pack(-side=>"left", -pady=>4);

    # Rhythmn Kit Number
    $fb->Label(
        -text               => '     Internal Bank Destination Kit Nr:',
        -font               => 'Sans 9',
        -pady               => 4
    )->pack(-side=>"left");
    $fb->Spinbox(%Entry_defaults,
        -width              => 3,
        -font               => 'Sans 9',
        -from               => 1,
        -to                 => 64,
        -increment          => 1,
        -state              => 'readonly',
        -readonlybackground => $LCDbg,
        -textvariable       => \$dest_rynr
    )->pack(-side=>"left");

    # Download Rythm Kit
    $fb->Label(
        -text         => '     Rhythm Kit Download from RM50:   Bank:',
        -font         => 'Sans 9',
        -justify      => 'right',
        -anchor       => 'e'
    )->pack(-side=>"left");

    $rybank_dwn_sel=$fb->BrowseEntry(%BEntry_defaults,
        -variable     => \$selected_rybank,
        -choices      => \@rykit,
        -font         => 'Sans 9',
        -width        => 8,
        -listheight   => 4,
        -browsecmd    => sub{ RefreshKitDwnList(); }
    )->pack(-side=>"left", -padx=>4);

    $rybank_dwn_sel->Subwidget("choices")->configure(%choices_defaults);
    $rybank_dwn_sel->Subwidget("arrow")->configure(%arrow_defaults);

    $fb->Label(
        -text         => " Voice:",
        -font         => 'Sans 9',
        -justify      => 'right',
        -anchor       => 'e'
    )->pack(-side=>"left");

    $rykit_dwn_sel=$fb->BrowseEntry(%BEntry_defaults,
        -variable     => \$selected_rykit,
        -choices      => $kithash{$selected_rybank},
        -font         => 'Sans 9',
        -width        => 13,
        -listheight   => 10
    )->pack(-side=>"left", -padx=>4);

    $rykit_dwn_sel->Subwidget("choices")->configure(%choices_defaults);
    $rykit_dwn_sel->Subwidget("arrow")->configure(%arrow_defaults);

    $rykitdwn_btn=$fb->Button(
        -font         => 'Sans 9',
        -text         => 'Download',
        -pady         => 0,
        -command      => sub{ my ($kitnr)=($selected_rykit=~/^(\d+):.*/);
                              my $banknr=0; if ($selected_rybank eq 'Internal') { $banknr=2; }
                                         elsif ($selected_rybank eq 'Card')     { $banknr=4; }
                              RcvSnglKitDmp($banknr, $kitnr-1); }
    )->pack(-side=>"left", -padx=>4, -pady=>4);

    if (($midi_indev eq '') || ($midi_outdev eq '')) { $rykitdwn_btn->configure(-state=>'disabled'); }

    my $line=$rywin->Frame(%Frame_defaults, -height=>2
    )->pack(-anchor=>'n', -fill=>'x');

    my $tb=$rywin->Frame(
    )->pack(-anchor=>'n', -fill=>'x');

    # MIDI channel
    $tb->Label(
        -text               => ' Ch:',
        -font               => 'Sans 9',
        -pady               => 4
    )->pack(-side=>"left");
    $tb->Spinbox(%Entry_defaults,
        -width              => 2,
        -font               => 'Sans 9',
        -from               => 1,
        -to                 => 16,
        -increment          => 1,
        -state              => 'readonly',
        -readonlybackground => $LCDbg,
        -textvariable       => \$ry_ch
    )->pack(-side=>"left");

    # Rhythmn Kit Name
    $tb->Label(
        -text               => '  Kit Name:',
        -font               => 'Sans 10',
        -pady               => 4
    )->pack(-side=>"left");
    $tb->Entry(%Entry_defaults,
        -width              => 10,
        -font               => 'Fixed 10',
        -validate           => 'key',
        -validatecommand    => sub {$_[0]=~/^[\x20-\x7F]{0,10}$/},
        -invalidcommand     => sub {},
        -textvariable       => \$kit_name
    )->pack(-side=>"left");

    # Pitch Bend Range
    $tb->Label(
        -text               => ' P.B Range:',
        -font               => 'Sans 9',
        -pady               => 4
    )->pack(-side=>"left");
    $tb->Spinbox(%Entry_defaults,
        -width              => 3,
        -font               => 'Sans 9',
        -from               => 0,
        -to                 => 12,
        -increment          => 1,
        -state              => 'readonly',
        -readonlybackground => $LCDbg,
        -textvariable       => \$ry_pbrange,
        -command            => sub{ SendRyChMsg(0,10,0,$ry_pbrange); }
    )->pack(-side=>"left");

    # Trigger Notes 1-6
    my @ry_trig;
    for (my $tr=1; $tr<=6; $tr++) {
            my $trg=$tr;
            $tb->Label(
                -text         => "  Trig$tr:",
                -font         => 'Sans 9'
            )->pack(-side=>"left");
            $ry_trig[$tr]=$tb->BrowseEntry(%BEntry_defaults,
                -variable     => \$ry_trnote[$tr],
                -choices      => \@notesl,
                -font         => 'Sans 9',
                -width        => 4,
                -browsecmd    => sub{ SendRyChMsg(0,(10+$trg),0,$noteshash{$ry_trnote[$trg]}); }
            )->pack(-side=>"left");
            $ry_trig[$tr]->Subwidget("choices")->configure(%choices_defaults);
            $ry_trig[$tr]->Subwidget("arrow")->configure(%arrow_defaults);
    }

    my $ryw=$rywin->Scrolled('Frame', -scrollbars=>'e', %Frame_defaults
    )->pack(-anchor=>'n', -fill=>'y', -expand=>1);

    $ryw->Label(%TitleLbl_defaults, -text=>'Note'       )->grid(-row=>0, -column=>0, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Bank'       )->grid(-row=>0, -column=>1, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Voice 1'    )->grid(-row=>0, -column=>2, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Attenuation')->grid(-row=>0, -column=>3, -columnspan=>2, -sticky=>'ew');

    $ryw->Label(%TitleLbl_defaults, -text=>'Bank'       )->grid(-row=>0, -column=>5, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Voice 2'    )->grid(-row=>0, -column=>6, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Attenuation')->grid(-row=>0, -column=>7, -columnspan=>2, -sticky=>'ew');

    $ryw->Label(%TitleLbl_defaults, -text=>'Mod'        )->grid(-row=>0, -column=>9, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Bal'        )->grid(-row=>0, -column=>10, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Fil'        )->grid(-row=>0, -column=>11, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Pan'        )->grid(-row=>0, -column=>12, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Dcy'        )->grid(-row=>0, -column=>13, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Vol'        )->grid(-row=>0, -column=>14, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'P.B'        )->grid(-row=>0, -column=>15, -sticky=>'ew');
    $ryw->Label(%TitleLbl_defaults, -text=>'Key'        )->grid(-row=>0, -column=>16, -sticky=>'ew');

    for (my $a=1; $a<=49; $a++) {
        my $end;
        if ($a<=24) { $end=1; } else { $end=0; }
        my $nn=$a;
        # note buttons
        my $plbt=$ryw->Button(
            -font         => 'title',
            -textvariable => \$note[$a+34],
        )->grid(-row=>$a, -column=>0, -padx=>4, -sticky=>'nsew');
        $plbt->bind('<Button-1>'        => sub { PlayMidiNote($ry_ch-1,$nn+34,127,1); });
        $plbt->bind('<ButtonRelease-1>' => sub { PlayMidiNote($ry_ch-1,$nn+34,127,0); });
        # loop for dual voice notes
        for (my $v=0; $v<=$end; $v++) {
            my $aa=$a; my $vv=$v;
            # bank selection
            $ry_bank_sel[$a][$v]=$ryw->BrowseEntry(%BEntry_defaults,
                -variable     => \$ry_bank[$a][$v],
                -choices      => [ $ry_bank[$a][$v] ],
                -font         => 'Sans 9',
                -width        => 6,
                -listcmd      => sub{ RefreshBnkList($aa, $vv); },
                -browsecmd    => sub{ RefreshVceList($aa, $vv, 1); }
            )->grid(-row=>$a, -column=>1+($v*4), -padx=>4);
            $ry_bank_sel[$a][$v]->Subwidget("choices")->configure(%choices_defaults);
            $ry_bank_sel[$a][$v]->Subwidget("arrow")->configure(%arrow_defaults);
            # voice selection
            $ry_voice_sel[$a][$v]=$ryw->BrowseEntry(%BEntry_defaults,
                -variable     => \$ry_voice[$a][$v],
                -choices      => [ $ry_voice[$a][$v] ],
                -font         => 'Sans 9',
                -width        => 12,
                -listcmd      => sub{ RefreshVceList($aa, $vv, 0); },
                -browsecmd    => sub{ SendVcChMsg($aa, $vv); }
            )->grid(-row=>$a, -column=>2+($v*4), -padx=>4);
            $ry_voice_sel[$a][$v]->Subwidget("choices")->configure(%choices_defaults);
            $ry_voice_sel[$a][$v]->Subwidget("arrow")->configure(%arrow_defaults);
            # Attenuation
            $ryw->Scale(%Scale_defaults,
                -variable     => \$ry_att[$a][$v],
                -to           =>  15,
                -from         =>   0,
                -tickinterval =>   3,
                -length       => 100,
                -command      => sub{ SendRyChMsg($aa,1+($vv*10),0,$ry_att[$aa][$vv]); }
            )->grid(-row=>$a, -column=>3+($v*4), -padx=>4);
            $ryw->Label(%Scale_label_defaults,
                -textvariable => \$ry_att[$a][$v], -width=>2
            )->grid(-row=>$a, -column=>4+($v*4), -padx=>4);
        }
        # Modulation
        $ryw->Checkbutton(
            -variable     => \$ry_mod[$a],
            -command      => sub{ SendRyChMsg($nn,9,0,$ry_mod[$nn]); }
        )->grid(-row=>$a, -column=>9);
        # Balance
        $ryw->Checkbutton(
            -variable     => \$ry_bal[$a],
            -command      => sub{ SendRyChMsg($nn,8,0,$ry_bal[$nn]); }
        )->grid(-row=>$a, -column=>10);
        # Filter
        $ryw->Checkbutton(
            -variable     => \$ry_flt[$a],
            -command      => sub{ SendRyChMsg($nn,7,0,$ry_flt[$nn]); }
        )->grid(-row=>$a, -column=>11);
        # Pan
        $ryw->Checkbutton(
            -variable     => \$ry_pan[$a],
            -command      => sub{ SendRyChMsg($nn,6,0,$ry_pan[$nn]); }
        )->grid(-row=>$a, -column=>12);
        # Decay
        $ryw->Checkbutton(
            -variable     => \$ry_dcy[$a],
            -command      => sub{ SendRyChMsg($nn,5,0,$ry_dcy[$nn]); }
        )->grid(-row=>$a, -column=>13);
        # Volume
        $ryw->Checkbutton(
            -variable     => \$ry_vol[$a],
            -command      => sub{ SendRyChMsg($nn,4,0,$ry_vol[$nn]); }
        )->grid(-row=>$a, -column=>14);
        # Pitch bend
        $ryw->Checkbutton(
            -variable     => \$ry_pbd[$a],
            -command      => sub{ SendRyChMsg($nn,3,0,$ry_pbd[$nn]); }
        )->grid(-row=>$a, -column=>15);
        # Key off
        $ryw->Checkbutton(
            -variable     => \$ry_kyo[$a],
            -command      => sub{ SendRyChMsg($nn,2,0,$ry_kyo[$nn]); }
        )->grid(-row=>$a, -column=>16);
    }

    # bottom status bar
    my $stb=$rywin->Frame(
        -borderwidth  => 1,
        -relief       => 'raised'
    ) -> pack(-side=>'bottom', -fill=>'x', -anchor=>'s');

    my $file_display=$stb->Label(
        -anchor       => 'w',
        -relief       => 'sunken',
        -borderwidth  => 1,
        -width        => 82,
        -font         => 'Sans 9',
        -textvariable => \$ryfilename
    )->pack(-side=>'left', -padx=>2, -pady=>2);

    $rymidiupload=$stb->Button(
        -text         => 'Upload via MIDI to RM50',
        -pady         => 2,
        -underline    => 0,
        -command      => \&SysexRyUpload
    )->pack(-side=>'right');
    $rywin->bind($rywin, "<Control-u>"=>\&SysexRyUpload);

    if ($midi_outdev ne '') {
        $rymidiupload->configure(-state=>'active');
    } else {
        $rymidiupload->configure(-state=>'disabled');
    }

}

#-------------------------------------------------------------------------------------------------------------------------
# LFO frame

sub LFO_Frame {
    my $elm=$_[0];
    $mf2[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf2[$elm]->Label(%TitleLbl_defaults, -text=> 'L F O'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf2[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# LFO Destination
    my $ldf=$subframe->Frame()->grid(-columnspan=>2);

    $ldf->Label(-text=>'Dest:', -font=>'Sans 8')->grid(-row=>0, -column=>0);
    my @ldlabel=('off', 'amplifier', 'pitch', 'filter');
    for (my $n=0;$n<=3;$n++) {
        $ldf->Radiobutton(
            -text     => $ldlabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$lfo_destination[$elm],
            -command  => sub{ SendPaChMsg($elm+1,25,0,$lfo_destination[$elm]); }
        )->grid(-row=>0, -column=>$n+1);
    }

# LFO Waveform Shape
    my $wff=$subframe->Frame()->grid(-columnspan=>2);

    $wff->Label(-text=>'LFO Waveform Shape:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>6);
    my @wflabel=('tri', 'dwn', 'up', 'squ', 'sin', 'S/H');
    for (my $n=0;$n<=5;$n++) {
        $wff->Radiobutton(
            -text     => $wflabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$lfo_wav_shape[$elm],
            -command  => sub{ SendPaChMsg($elm+1,21,0,$lfo_wav_shape[$elm]); }
        )->grid(-row=>1, -column=>$n);
    }

# LFO Mod Speed
    $subframe->Scale(%Scale_defaults,
        -variable     => \$lfo_mod_speed[$elm],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'LFO Modulation Speed',
        -command      => sub{ SendPaChMsg($elm+1,23,0,$lfo_mod_speed[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$lfo_mod_speed[$elm]
    ),-padx=>4);

# LFO Mod Depth
    $subframe->Scale(%Scale_defaults,
        -variable     => \$lfo_mod_depth[$elm],
        -to           => 127,
        -from         =>   0,
        -tickinterval =>  20,
        -label        => 'LFO Modulation Depth',
        -command      => sub{ SendPaChMsg($elm+1,27,0,$lfo_mod_depth[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$lfo_mod_depth[$elm]
    ),-padx=>4);

# LFO Delay
    $subframe->Scale(%Scale_defaults,
        -variable     => \$lfo_delay[$elm],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'LFO Delay',
        -command      => sub{ SendPaChMsg($elm+1,24,0,$lfo_delay[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$lfo_delay[$elm]
    ),-padx=>4);

# LFO Phase
    $subframe->Scale(%Scale_defaults,
        -variable     => \$lfo_phase[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'LFO Phase',
        -command      => sub{ SendPaChMsg($elm+1,26,0,$lfo_phase[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$lfo_phase[$elm]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Filter Frame

sub Filter_Frame {
    my $elm=$_[0];
    $mf3[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf3[$elm]->Label(%TitleLbl_defaults, -text=> 'Filter'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf3[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Filter Type
    my $ftf=$subframe->Frame()->grid(-columnspan=>2, -pady=>2);

    my @ftlabel=('Thru', 'LPF12', 'LPF24', 'HPF12', 'HPF24');
    for (my $n=0;$n<=4;$n++) {
        $ftf->Radiobutton(
            -text     => $ftlabel[$n],
            -font     => 'Sans 7',
            -value    => $n,
            -variable => \$filter_type[$elm],
            -command  => sub{ SendPaChMsg($elm+1,12,0,$filter_type[$elm]); }
        )->grid(-row=>0, -column=>$n);
    }

# Filter Cutoff Frq
    $subframe->Scale(%Scale_defaults,
        -variable     => \$filter_cutoff_frq[$elm],
        -to           => 127,
        -from         =>   0,
        -tickinterval =>  20,
        -label        => 'Filter Cutoff Frequency',
        -command      => sub{ SendPaChMsg($elm+1,13,0,$filter_cutoff_frq[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$filter_cutoff_frq[$elm]
    ),-padx=>4);

# Filter Resonance
    $subframe->Scale(%Scale_defaults,
        -variable     => \$filter_resonance[$elm],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Filter Resonance',
        -command      => sub{ SendPaChMsg($elm+1,14,0,$filter_resonance[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$filter_resonance[$elm]
    ),-padx=>4);

# Filter EG Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$filter_eg_level[$elm],
        -to           =>  63,
        -from         => -63,
        -tickinterval =>  14,
        -label        => 'Filter EG Level',
        -command      => sub{ SendPaChMsg($elm+1,15,0,$filter_eg_level[$elm]+63); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$filter_eg_level[$elm]
    ),-padx=>4);

# Filter EG Rate
    $subframe->Scale(%Scale_defaults,
        -variable     => \$filter_eg_rate[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Filter EG Rate',
        -command      => sub{ SendPaChMsg($elm+1,16,0,$filter_eg_rate[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$filter_eg_rate[$elm]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Amplifier EG Frame

sub EG_Frame {
    my $elm=$_[0];
    $mf4[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf4[$elm]->Label(%TitleLbl_defaults, -text=> 'Amplifier Envelope Generator'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf4[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Amp EG Attack
    $subframe->Scale(%Scale_defaults,
        -variable     => \$eg_attack[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'EG Attack',
        -command      => sub{ SendPaChMsg($elm+1,8,0,$eg_attack[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$eg_attack[$elm]
    ),-padx=>4);

# Amp EG Punch
    $subframe->Scale(%Scale_defaults,
        -variable     => \$eg_punch[$elm],
        -to           =>  7,
        -from         =>  0,
        -tickinterval =>  1,
        -label        => 'EG Punch',
        -command      => sub{ SendPaChMsg($elm+1,11,0,$eg_punch[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$eg_punch[$elm]
    ),-padx=>4);

# Amp EG Decay
    $subframe->Scale(%Scale_defaults,
        -variable     => \$eg_decay[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'EG Decay',
        -command      => sub{ SendPaChMsg($elm+1,9,0,$eg_decay[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$eg_decay[$elm]
    ),-padx=>4);

# Amp EG Release
    $subframe->Scale(%Scale_defaults,
        -variable     => \$eg_release[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'EG Release',
        -command      => sub{ SendPaChMsg($elm+1,10,0,$eg_release[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$eg_release[$elm]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Sensitivity Frame

sub Sens_Frame {
    my $elm=$_[0];
    $mf5[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf5[$elm]->Label(%TitleLbl_defaults, -text=> 'Sensitivity'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf5[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Velocity Curve
    my $elm_velcurve_fn=$subframe->Frame()->grid(-columnspan=>2);

    $elm_velcurve_fn->Label(-text=>'Velocity Curve: ', -font=>'Sans 8')->grid(
    my $elm_velcurve_entry=$elm_velcurve_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$elm_velcurve[$elm],
        -choices      => \@vlcurves,
        -width        => 14,
        -browsecmd    => sub{ my ($velcnr)=($elm_velcurve[$elm]=~/^(\d+):.*/); SendPaChMsg($elm+1,33,0,$velcnr-1); }
    ));
    $elm_velcurve_entry->Subwidget("choices")->configure(%choices_defaults);
    $elm_velcurve_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Sensitivity Output Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$sens_level[$elm],
        -to           =>  7,
        -from         => -7,
        -tickinterval =>  1,
        -label        => 'Output Level sensitivity to Velocity',
        -command      => sub{ SendPaChMsg($elm+1,17,0,($sens_level[$elm]<0?abs($sens_level[$elm])+8:$sens_level[$elm])); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$sens_level[$elm]
    ),-padx=>4);

# Sensitivity Pitch
    $subframe->Scale(%Scale_defaults,
        -variable     => \$sens_pitch[$elm],
        -to           =>  7,
        -from         => -7,
        -tickinterval =>  1,
        -label        => 'Pitch sensitivity to Velocity',
        -command      => sub{ SendPaChMsg($elm+1,18,0,($sens_pitch[$elm]<0?abs($sens_pitch[$elm])+8:$sens_pitch[$elm])); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$sens_pitch[$elm]
    ),-padx=>4);

# Sensitivity Amplifier EG
    $subframe->Scale(%Scale_defaults,
        -variable     => \$sens_eg[$elm],
        -to           =>  7,
        -from         => -7,
        -tickinterval =>  1,
        -label        => 'Amplifier EG sensitivity to Velocity',
        -command      => sub{ SendPaChMsg($elm+1,19,0,($sens_eg[$elm]<0?abs($sens_eg[$elm])+8:$sens_eg[$elm])); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$sens_eg[$elm]
    ),-padx=>4);

# Sensitivity Filter Cutoff Freq
    $subframe->Scale(%Scale_defaults,
        -variable     => \$sens_filter[$elm],
        -to           =>  7,
        -from         => -7,
        -tickinterval =>  1,
        -label        => 'Filter Cutoff Freq sensitivity to Velocity',
        -command      => sub{ SendPaChMsg($elm+1,20,0,($sens_filter[$elm]<0?abs($sens_filter[$elm])+8:$sens_filter[$elm])); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$sens_filter[$elm]
    ),-padx=>4);

# Sensitivity LFO Modulation
    $subframe->Scale(%Scale_defaults,
        -variable     => \$sens_modul[$elm],
        -to           =>  7,
        -from         =>  0,
        -tickinterval =>  1,
        -label        => 'LFO Modulation sensitivity to Modulation',
        -command      => sub{ SendPaChMsg($elm+1,22,0,$sens_modul[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$sens_modul[$elm]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Delay Frame

sub Delay_Frame {
    my $elm=$_[0];
    $mf6[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf6[$elm]->Label(%TitleLbl_defaults, -text=> 'Delay Effect'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf6[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Delay First Note
    my $del_fn=$subframe->Frame()->grid(-columnspan=>2);

    $del_fn->Label(-text=>'Play first note: ', -font=>'Sans 8')->grid(-row=>0, -column=>0);
    my @dellabel=('off', 'on');
    for (my $n=0;$n<=1;$n++) {
        $del_fn->Radiobutton(
            -text     => $dellabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$del_first_note[$elm],
            -command  => sub{ SendPaChMsg($elm+1,29,0,$del_first_note[$elm]); }
        )->grid(-row=>0, -column=>$n+1);
    }

# Delay Repetition
    $subframe->Scale(%Scale_defaults,
        -variable     => \$delay_repetition[$elm],
        -to           =>  7,
        -from         =>  0,
        -tickinterval =>  1,
        -label        => 'Delay Repetitions (0 = off)',
        -command      => sub{ SendPaChMsg($elm+1,31,0,$delay_repetition[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$delay_repetition[$elm]
    ),-padx=>4);

# Delay Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$delay_time[$elm],
        -to           => 128,
        -from         =>   1,
        -tickinterval =>  20,
        -label        => 'Delay Time',
        -command      => sub{ SendPaChMsg($elm+1,30,0,$delay_time[$elm]-1); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$delay_time[$elm]
    ),-padx=>4);

# Delay Level Offset
    $subframe->Scale(%Scale_defaults,
        -variable     => \$delay_lvl_offset[$elm],
        -to           =>  15,
        -from         => -15,
        -tickinterval =>   3,
        -label        => 'Delay Level Offset',
        -command      => sub{ SendPaChMsg($elm+1,32,($delay_lvl_offset[$elm]<0?1:0),
                             ($delay_lvl_offset[$elm]<0?128-abs($delay_lvl_offset[$elm]):$delay_lvl_offset[$elm]) ); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$delay_lvl_offset[$elm]
    ),-padx=>4);

# Delay Pitch Offset
    $subframe->Scale(%Scale_defaults,
        -variable     => \$delay_pch_offset[$elm],
        -to           =>  12.0,
        -from         => -12.0,
        -resolution   =>   0.1,
        -tickinterval =>   4,
        -label        => 'Delay Pitch Offset',
        -command      => sub{ SendPaChMsg($elm+1,2,($delay_pch_offset[$elm]<0?1:0),
                             ($delay_pch_offset[$elm]<0?128-abs($delay_pch_offset[$elm]*10):$delay_pch_offset[$elm]*10) ); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$delay_pch_offset[$elm], -width=>4
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Misc Frame

sub Misc_Frame {
    my $elm=$_[0];
    $mf7[$elm]=$tab[$elm]->Frame(%Frame_defaults);

    $mf7[$elm]->Label(%TitleLbl_defaults, -text=> 'Waveform'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf7[$elm]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Wave and Wave playback direction
    my $elm_wave_fn=$subframe->Frame()->grid(-columnspan => 2);

    $wave_source_sel[$elm]=$elm_wave_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$wave_source[$elm],
        -choices      => \@wsources,
        -browsecmd    => sub{ UpdateWSel($elm,0); SendWvChMsg($elm); },
        -width        => 7,
        -listheight   => 3
    )->grid(
    $elm_wave_fn->Label(
        -text         => " Wave:",
        -font         => 'Sans 8'
    ),
    $elm_wave_entry[$elm]=$elm_wave_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$elm_wave[$elm],
        -choices      => $wavehash{$wave_source[$elm]},
        -width        => 12,
        -listheight   => 10,
        -browsecmd    => sub{ SendWvChMsg($elm); }
    ),
    $elm_wave_fn->Checkbutton(
        -text         => 'Rev',
        -font         => 'Sans 8',
        -variable     => \$wave_dir[$elm],
        -command      => sub{ SendPaChMsg($elm+1,7,0,$wave_dir[$elm]); }
    ));
    $elm_wave_entry[$elm]->Subwidget("choices")->configure(%choices_defaults);
    $elm_wave_entry[$elm]->Subwidget("arrow")->configure(%arrow_defaults);
    $wave_source_sel[$elm]->Subwidget("choices")->configure(%choices_defaults);
    $wave_source_sel[$elm]->Subwidget("arrow")->configure(%arrow_defaults);

# Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$elm_level[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Level',
        -command      => sub{ SendPaChMsg($elm+1,3,0,$elm_level[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$elm_level[$elm]
    ),-padx=>4);

# Pan
    $subframe->Scale(%Scale_defaults,
        -variable     => \$elm_pan[$elm],
        -to           =>  32,
        -from         =>   0,
        -tickinterval =>   4,
        -label        => 'Pan',
        -command      => sub{ SendPaChMsg($elm+1,4,0,$elm_pan[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$elm_pan[$elm]
    ),-padx=>4);

# Pitch
    $subframe->Scale(%Scale_defaults,
        -variable     => \$elm_pitch[$elm],
        -to           =>  3600,
        -from         => -3600,
        -tickinterval =>  1200,
        -label        => 'Pitch',
        -command      => sub{ SendPaChMsg($elm+1,6,0,($elm_pitch[$elm]+3600)%100); SendPaChMsg($elm+1,5,0,int(($elm_pitch[$elm]+3600)/100)); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$elm_pitch[$elm], -width=>5
    ),-padx=>2);

# Pitch EG Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$pitch_eg_lvl[$elm],
        -to           =>  72,
        -from         => -72,
        -tickinterval =>  18,
        -label        => 'Pitch EG Level',
        -command      => sub{ SendPaChMsg($elm+1,1,int(($pitch_eg_lvl[$elm]+72)/128),($pitch_eg_lvl[$elm]+72)%128); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$pitch_eg_lvl[$elm]
    ),-padx=>4);

# Pitch EG Rate
    $subframe->Scale(%Scale_defaults,
        -variable     => \$pitch_eg_rate[$elm],
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Pitch EG Rate',
        -command      => sub{ SendPaChMsg($elm+1,28,0,$pitch_eg_rate[$elm]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$pitch_eg_rate[$elm]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Common Frame

sub Common_Frame {
    $mf10=$tab[0]->Frame(%Frame_defaults)->pack(-side=>'left', -fill=>'y');

    $mf10->Label(%TitleLbl_defaults, -text=> 'Common Voice Parameters'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$mf10->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Voice Name
    # voice name window width: 8 for Linux, 9 for Windows
    my $vcn_width;
    if ($WINDOWS) { $vcn_width=9; } else { $vcn_width=8; }

    my $vname=$subframe->Frame()->grid(-columnspan=>2, -pady=>5);

    $vname->Label(-text=>'Voice Name (1-8 chars): ', -font=>'Sans 10')->grid(
    $vname->Entry(%Entry_defaults,
        -width              => $vcn_width,
        -font               => 'Fixed 10',
        -validate           => 'key',
        -validatecommand    => sub {$_[0]=~/^[\x20-\x7F]{0,8}$/},
        -invalidcommand     => sub {},
        -textvariable       => \$voice_name
    ));

# Output
    my $outf=$subframe->Frame()->grid(-columnspan=>2);

    $outf->Label(-text=>'Output:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>7);
    my @outlabel=0..6; $outlabel[0]='stereo';
    for (my $n=0;$n<=6;$n++) {
        $outf->Radiobutton(
            -text     => $outlabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$voutput,
            -command  => sub{ SendPaChMsg(1,9,0,$voutput); }
        )->grid(-row=>1, -column=>$n);
    }

# Alternate Group
    my $altgf=$subframe->Frame()->grid(-columnspan=>2);

    $altgf->Label(-text=>'Alternate Group:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>8);
    my @altglabel=0..7; $altglabel[0]='off';
    for (my $n=0;$n<=7;$n++) {
        $altgf->Radiobutton(
            -text     => $altglabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$altgroup,
            -command  => sub{ SendPaChMsg(1,8,0,$altgroup); }
        )->grid(-row=>1, -column=>$n);
    }

# Assign
    my $asgnf=$subframe->Frame()->grid(-columnspan=>2);

    $asgnf->Label(-text=>'Assign:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>4);
    my @aslabel=('mono', 'poly', 'mono/alt', 'poly/alt');
    for (my $n=0;$n<=3;$n++) {
        $asgnf->Radiobutton(
            -text     => $aslabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$vassign,
            -command  => sub{ SendPaChMsg(1,10,0,$vassign); }
        )->grid(-row=>1, -column=>$n);
    }

# Volume
    $subframe->Scale(%Scale_defaults,
        -variable     => \$volume,
        -to           => 127,
        -from         =>   0,
        -tickinterval =>  20,
        -label        => 'Volume',
        -command      => sub{ SendPaChMsg(0,0,0,$volume); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$volume
    ),-padx=>4);

# Pan
    $subframe->Scale(%Scale_defaults,
        -variable     => \$pan,
        -to           =>  32,
        -from         => -32,
        -tickinterval =>   8,
        -label        => 'Pan',
        -command      => sub{ SendPaChMsg(0,1,0,$pan+32); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$pan
    ),-padx=>4);

# Pitch
    $subframe->Scale(%Scale_defaults,
        -variable     => \$pitch,
        -to           =>  64,
        -from         => -64,
        -tickinterval =>  16,
        -label        => 'Pitch',
        -command      => sub{ SendPaChMsg(0,2,int(($pitch+64)/128),($pitch+64)%128); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$pitch
    ),-padx=>4);

# Decay
    $subframe->Scale(%Scale_defaults,
        -variable     => \$decay,
        -to           =>  64,
        -from         => -64,
        -tickinterval =>  16,
        -label        => 'Decay',
        -command      => sub{ SendPaChMsg(0,3,int(($decay+64)/128),($decay+64)%128); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$decay
    ),-padx=>4);

# Filter Cutoff Freq
    $subframe->Scale(%Scale_defaults,
        -variable     => \$cfilter_cutoff_freq,
        -to           =>  64,
        -from         => -64,
        -tickinterval =>  16,
        -label        => 'Filter Cutoff Frequency',
        -command      => sub{ SendPaChMsg(0,4,int(($cfilter_cutoff_freq+64)/128),($cfilter_cutoff_freq+64)%128); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$cfilter_cutoff_freq
    ),-padx=>4);

# Balance
    $subframe->Scale(%Scale_defaults,
        -variable     => \$balance,
        -to           =>  64,
        -from         => -64,
        -tickinterval =>  16,
        -label        => 'Balance',
        -command      => sub{ SendPaChMsg(0,5,int(($balance+64)/128),($balance+64)%128); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$balance
    ),-padx=>4);

# Individual Output Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$indiv_level,
        -to           =>  63,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Individual Output Level',
        -command      => sub{ SendPaChMsg(1,11,0,$indiv_level); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$indiv_level
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Settings Frame

sub Settings_Frame {
    $mf11=$tab[0]->Frame(%Frame_defaults, -padx=>0, -pady=>0, -borderwidth=>0
    )->pack(-fill=>'both', -expand=>1);

# photo of RM50 front panel (purely for decorative purposes)
    my $jpg1=$mf11->Photo( '-format'=>'jpeg', -file=>'yamaha_rm50.jpg');
    $mf11->Label(-image=>$jpg1, -borderwidth=>0, -relief=>'flat', -anchor=>'n',-height=>55
    )->pack(-anchor=>'n', -fill=>'x', -ipadx=>3);

# Inserted Wave and Data Cards
    my $wave_card_fn=$mf11->Frame(%Frame_defaults
    )->pack(-anchor=>'n', -fill=>'x', -padx=>4, -pady=>4);

    $wave_card_fn->Label(%TitleLbl_defaults,
        -text         => "Inserted Waveform and Data Cards"
    )->pack(-fill=>'x', -expand=>1);

    my $wave_card_sub=$wave_card_fn->Frame(
    )->pack(-fill=>'x', -expand=>1, -pady=>14);

    for (my $i=1; $i<=3; $i++) {
        my $card=$i;
        my $spc="";
        if ($i==3) { $spc=" "; }
        $wave_card_sub->Label(
            -text         => $spc."Wave Card $i:",
            -font         => 'Sans 8'
        )->grid(-row=>(int(($i+1)/3)), -column=>(int(($i)/3)*2), -pady=>8);

        my $wave_card_entry=$wave_card_sub->BrowseEntry(%BEntry_defaults,
            -variable     => \$wave_card[$i],
            -choices      => \@wavecards,
            -browsecmd    => sub{ InsRemWavCard($card); },
            -width        => 23
        )->grid(-row=>(int(($i+1)/3)), -column=>(int(($i)/3)*2+1), -pady=>8 );

        $wave_card_entry->Subwidget("choices")->configure(%choices_defaults);
        $wave_card_entry->Subwidget("arrow")->configure(%arrow_defaults);
    }

    $wave_card_sub->Label(
            -text         => "Data Card:",
            -font         => 'Sans 8'
    )->grid(-row=>0, -column=>2, -pady=>8, -sticky=>'e');

    my $data_card_entry=$wave_card_sub->BrowseEntry(%BEntry_defaults,
            -variable     => \$data_card,
            -choices      => \@datacards,
            -browsecmd    => sub{ InsRemDatCard(); },
            -width        => 23,
            -listheight   => 5
    )->grid(-row=>0, -column=>3, -pady=>8);

    $data_card_entry->Subwidget("choices")->configure(%choices_defaults);
    $data_card_entry->Subwidget("arrow")->configure(%arrow_defaults);


# RM50 device number and I-MX (user) bank destination voice config boxes

    my $misc_settings=$mf11->Frame(%Frame_defaults
    )->pack(-anchor=>'n', -fill=>'x', -padx=>4);

    $misc_settings->Label(%TitleLbl_defaults,
        -text         => "Device and Destination Voice Settings"
    )->pack(-fill=>'x', -expand=>1);

    my $misc_sett_sub=$misc_settings->Frame(
    )->pack(-fill=>'x', -expand=>1, -pady=>15);

    $misc_sett_sub->Label(
        -text         => "Yamaha RM50 Device Nr:",
        -font         => 'Sans 9'
    )->grid(-row=>0, -column=>0, -sticky=>'e');

    my $dev_entry=$misc_sett_sub->Spinbox(%Entry_defaults,
        -width              => 3,
        -font               => 'Sans 9',
        -from               => 1,
        -to                 => 16,
        -increment          => 1,
        -state              => 'readonly',
        -readonlybackground => $LCDbg,
        -validate           => 'key',
        -validatecommand    => sub {(($_[0] eq "") || ($_[0]=~/^[0-9]+$/ && $_[0]>=1 && $_[0]<=16))},
        -invalidcommand     => sub {},
        -textvariable       => \$dev_nr
    )->grid(-row=>0, -column=>1, -sticky=>'w', -padx=>2, -pady=>7);

    $misc_sett_sub->Label(
        -text         => "  ",
        -font         => 'Sans 9'
    )->grid(-row=>0, -column=>2, -sticky=>'ew');

    $misc_sett_sub->Label(
        -text         => "  I-MX Bank Destination Voice Nr:",
        -font         => 'Sans 9'
    )->grid(-row=>0, -column=>3, -sticky=>'e');

    my $dest_entry=$misc_sett_sub->Spinbox(%Entry_defaults,
        -width              => 3,
        -font               => 'Sans 9',
        -from               => 1,
        -to                 => 128,
        -increment          => 1,
        -state              => 'readonly',
        -readonlybackground => $LCDbg,
        -validate           => 'key',
        -validatecommand    => sub {(($_[0] eq "") || ($_[0]=~/^[0-9]+$/ && $_[0]>=1 && $_[0]<=128))},
        -invalidcommand     => sub {},
        -textvariable       => \$dest_vnr
    )->grid(-row=>0, -column=>4, -sticky=>'w', -padx=>2, -pady=>7);


# MIDI input and output devices selection

    my $midi_settings=$mf11->Frame(%Frame_defaults
    )->pack(-anchor=>'n', -fill=>'x', -padx=>4, -pady=>4);

    $midi_settings->Label(%TitleLbl_defaults,
        -text         => "MIDI Devices Configuration"
    )->pack(-fill=>'x', -expand=>1);

    my $midi_sett_sub=$midi_settings->Frame(
    )->pack(-fill=>'x', -expand=>1, -pady=>14);

    $midi_sett_sub->Label(
        -text         => "Output MIDI Device to Yamaha RM50: ",
        -font         => 'Sans 9',
        -justify      => 'right'
    )->grid(-row=>0, -column=>0, -sticky=>'e', -pady=>8);

    $midiout=$midi_sett_sub->BrowseEntry(%BEntry_defaults,
        -variable     => \$midi_outdev,
        -choices      => \@midi_outdevs,
        -font         => 'Sans 9',
        -width        => 28,
        -listheight   => 9,
        -browsecmd    => sub{ MidiConSetup('out'); },
        -listcmd      => sub{ @midi_outdevs=MidiPortList('out');
                              $midiout->delete( 0, "end" );
                              $midiout->insert("end", $_) for (@midi_outdevs); }
    )->grid(-row=>0, -column=>1, -sticky=>'w', -pady=>8);

    $midiout->Subwidget("choices")->configure(%choices_defaults);
    $midiout->Subwidget("arrow")->configure(%arrow_defaults);

    if (!$LINUX && !$WINDOWS) { $midiout->configure(-state=>'disabled'); }

    $midi_sett_sub->Label(
        -text         => "Input MIDI Device from Yamaha RM50: ",
        -font         => 'Sans 9',
        -justify      => 'right'
    )->grid(-row=>1, -column=>0, -sticky=>'e', -pady=>8);

    $midiin=$midi_sett_sub->BrowseEntry(%BEntry_defaults,
        -variable     => \$midi_indev,
        -choices      => \@midi_indevs,
        -font         => 'Sans 9',
        -width        => 28,
        -listheight   => 9,
        -browsecmd    => sub{ MidiConSetup('in'); },
        -listcmd      => sub{ @midi_indevs=MidiPortList('in');
                              $midiin->delete( 0, "end" );
                              $midiin->insert("end", $_) for (@midi_indevs); }
    )->grid(-row=>1, -column=>1, -sticky=>'w', -pady=>8);

    $midiin->Subwidget("choices")->configure(%choices_defaults);
    $midiin->Subwidget("arrow")->configure(%arrow_defaults);

    if (!$LINUX) { $midiin->configure(-state=>'disabled'); }

# Single voice download from RM50 frame

    my $voice_download=$mf11->Frame(%Frame_defaults
    )->pack(-anchor=>'n', -fill=>'both', -expand=>1, -padx=>4);

    $voice_download->Label(%TitleLbl_defaults,
        -text         => "Voice Download from RM50"
    )->pack(-anchor=>'n', -fill=>'x', -expand=>1);

    my $voice_dwn_sub=$voice_download->Frame(
    )->pack(-anchor=>'n', -fill=>'x', -expand=>1, -pady=>14);

    $voice_dwn_sub->Label(
        -text         => "Bank: ",
        -font         => 'Sans 9',
        -justify      => 'right',
        -anchor       => 'e'
    )->grid(-row=>1, -column=>0);

    $bank_dwn_sel=$voice_dwn_sub->BrowseEntry(%BEntry_defaults,
        -variable     => \$selected_bank,
        -choices      => \@banks_array,
        -font         => 'Sans 9',
        -width        => 6,
        -listheight   => 10,
        -browsecmd    => sub{ RefreshVceDwnList(); }
    )->grid(-row=>1, -column=>1);

    $bank_dwn_sel->Subwidget("choices")->configure(%choices_defaults);
    $bank_dwn_sel->Subwidget("arrow")->configure(%arrow_defaults);

    $voice_dwn_sub->Label(
        -text         => "     Voice: ",
        -font         => 'Sans 9',
        -justify      => 'right',
        -anchor       => 'e'
    )->grid(-row=>1, -column=>2);

    $voice_dwn_sel=$voice_dwn_sub->BrowseEntry(%BEntry_defaults,
        -variable     => \$selected_voice,
        -choices      => $voiceshash{$selected_bank},
        -font         => 'Sans 9',
        -width        => 12,
        -listheight   => 10
    )->grid(-row=>1, -column=>3);

    $voice_dwn_sel->Subwidget("choices")->configure(%choices_defaults);
    $voice_dwn_sel->Subwidget("arrow")->configure(%arrow_defaults);

    $vcdwn_btn=$voice_dwn_sub->Button(
        -font         => 'Sans 9',
        -text         => 'Download',
        -command      => sub{ my ($voicenr)=($selected_voice=~/^(\d+):.*/);
                              RcvSnglVceDmp($bankshash{$selected_bank}, $voicenr-1); }
    )->grid(-row=>1, -column=>4, -padx=>36, -pady=>8);

    if (($midi_indev eq '') || ($midi_outdev eq '')) { $vcdwn_btn->configure(-state=>'disabled'); }

}

