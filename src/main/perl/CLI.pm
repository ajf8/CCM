# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package EDG::WP4::CCM::CLI;

use strict;
use warnings;

use base qw(EDG::WP4::CCM::Options);
use LC::Exception qw(SUCCESS);
use EDG::WP4::CCM::TextRender qw(ccm_format @CCM_FORMATS);
use Readonly;

Readonly::Hash my %CLI_ACTIONS => {
    show => 'Print the tree starting from the selected path.',
};

Readonly my $DEFAULT_ACTION => 'show';

=head1 NAME

EDG::WP4::CCM::CLI

=head1 DESCRIPTION

This module inplements the CCM CLI. The final script should be rather minimal,
and a module allows for far easier unittesting.

=cut

sub _initialize {

    my ($self, $cmd, @args) = @_;

    my $argsref = \@args;

    $self->add_actions(\%CLI_ACTIONS);

    $self->default_action($DEFAULT_ACTION);

    my $res = $self->SUPER::_initialize($cmd, $argsref);

    # Final arguments are all profpaths
    if (@$argsref) {
        $self->{profpaths} = $argsref;
        $self->debug(2, "Add non-option cmdline profpaths: ", join(',', $self->{profpaths}));
    } else {
        $self->{profpaths} = [];
        $self->debug(2, "No non-option cmdline profpaths");
    };

    return $res;
}

# extend the CCM::Options
sub app_options
{
    my $self = shift;

    my $opts = $self->SUPER::app_options(@_);

    push(@$opts,
         {
             NAME => 'format=s',
             DEFAULT => 'query',
             HELP => 'Select the format (avail: ' . join(', ', @CCM_FORMATS). ')',
         },
    );

    return $opts;
}

=pod

=over

=item action_show

Print the tree starting from the selected path(s). Not existing paths are skipped.

=cut

sub action_show
{
    my $self = shift;

    my $cfg = $self->getCCMConfig();
    return if (! defined($cfg));

    foreach my $path (@{$self->gatherPaths(@{$self->{profpaths}})}) {
        if(! $cfg->elementExists($path)) {
            $self->debug(4, "action_show: no element for path $path");
            next;
        }

        my $trd = ccm_format(
            $self->option('format'),
            $cfg->getElement($path),
            );
        if(! defined($trd)) {
            $self->debug(3, "action_show: invalid format ", $self->option('format'));
            return;
        }

        my $fmt_txt = $trd->get_text();

        # TODO: no fail on renderfailure?
        if(defined($fmt_txt)) {
            $self->_print($fmt_txt);
        } else {
            $self->debug(3, "action_show: Renderfailure for path $path",
                         " and format ", $self->option('format'),
                         ": ", $trd->{fail});
            return;
        };
    }

    return SUCCESS;
}

=pod

=back

=cut


1;
