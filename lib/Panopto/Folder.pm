package Panopto::Folder;

use strict;
use warnings;

use Panopto::Interface::SessionManagement;
use Panopto::Interface::AccessManagement;


sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


sub Create {
    my $self = shift;
    my %args = (
        name         => undef, # string
        parentFolder => undef, # guid
        isPublic     => undef, # boolean
        @_
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->AddFolder(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( name => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( parentFolder => $args{'parentFolder'} ),
        SOAP::Data->prefix('tns')->name( isPublic => $args{'isPublic'}?'true':'false' ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = $som->result->{$key};
    }

    return $self->Id;
}


sub ProvisionExternalCourse {
    my $self = shift;
    my %args = (
        name         => undef, # string
        externalId   => undef, # string
        @_
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ProvisionExternalCourse(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( name       => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( externalId => $args{'externalId'} ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = $som->result->{$key};
    }

    return $self->Id;
}



sub SetExternalCourseAccess {
    my $self = shift;
    my %args = (
        name         => undef, # string
        externalId   => undef, # string
        @_
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->SetExternalCourseAccess(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( name       => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( externalId => $args{'externalId'} ),
        SOAP::Data->prefix('tns')->name('folderIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => $self->Id ),
            )
        )
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = $som->result->{$key};
    }

    return $self->Id;
}



sub Load {
    my $self = shift;
    my $id = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;
    if ( $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i ) {
        # Query by guid
        $som = $soap->GetFoldersById(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name('folderIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
                \SOAP::Data->value(
                    SOAP::Data->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetAllFoldersByExternalId(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name('folderExternalIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
                \SOAP::Data->value(
                    SOAP::Data->name( string => $id ),
                )
            ) );
    }

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return ( undef, 'Folder not found' )
        unless ref $som->result eq 'HASH';

    return ( undef, 'Folder not found?' )
        unless $som->result->{'Folder'};

    for my $key ( keys %{$som->result->{'Folder'}} ) {
        $self->{$key} = defined($som->result->{'Folder'}->{$key}) ? $som->result->{'Folder'}->{$key} : '';
    }

    return $self->Id;
}


sub SessionsObj {
    my $self = shift;

    use Panopto::Sessions;
    my $sessions = Panopto::Sessions->new( %{$self->Sessions} );

    return $sessions;
}


sub SetName {
    my $self = shift;

    my $name = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateFolderName(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( name => $name ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return ( 1, "Name changed" );
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateFolderExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub SetParent {
    my $self = shift;
    my $parentId = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateFolderParent(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( parentId => $parentId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub SetDescription {
    my $self = shift;
    my $description = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    $description =~ s/&/&amp;/g;

    my $som = $soap->UpdateFolderDescription(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( description => $description ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub LoadAccessDetails {
    my $self = shift;

    my $soap = new Panopto::Interface::AccessManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetFolderAccessDetails(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless ref $som->result eq 'HASH';

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = defined($som->result->{$key}) ? $som->result->{$key} : '';
    }

    return 1;

}


sub RevokeUserAccess {
    my $self = shift;
    my %args = (
        userId  => undef, # guid
        role    => undef, # string: Creator or Viewer
        @_
        );

    my $soap = new Panopto::Interface::AccessManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->RevokeUsersAccessFromFolder(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name('userIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => $args{'userId'} ),
            )
        ),
        SOAP::Data->prefix('tns')->name( role     => $args{'role'} ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless ref $som->result eq 'HASH';

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = $som->result->{$key};
    }

    return 1;

}


sub RevokeGroupAccess {
    my $self = shift;
    my %args = (
        groupId => undef, # guid
        role    => undef, # string: Creator or Viewer
        @_
        );

    my $soap = new Panopto::Interface::AccessManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->RevokeGroupAccessFromFolder(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( groupId  => $args{'groupId'} ),
        SOAP::Data->prefix('tns')->name( role     => $args{'role'} ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless ref $som->result eq 'HASH';

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = $som->result->{$key};
    }

    return 1;

}


sub _ACL {
    my $self = shift;
    my $acltype = shift;

    return undef unless $self->{$acltype};

    return { guid => [ $self->{$acltype}->{'guid'} ] }
        if ref $self->{$acltype}->{'guid'} ne 'ARRAY';

    return $self->{$acltype};
}


sub UsersWithViewerAccess {
    my $self = shift;

    return $self->_ACL('UsersWithViewerAccess');
}

sub UsersWithCreatorAccess {
    my $self = shift;

    return $self->_ACL('UsersWithCreatorAccess');
}

sub GroupsWithViewerAccess {
    my $self = shift;

    return $self->_ACL('GroupsWithViewerAccess');
}

sub GroupsWithCreatorAccess {
    my $self = shift;

    return $self->_ACL('GroupsWithCreatorAccess');
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $method;

    if ( ($method) = $AUTOLOAD =~ /.*::(\w+)/ and defined($self->{$method}) ) {
        return $self->{$method};
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}


1;
