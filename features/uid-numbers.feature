Feature: LDAP UIDs are imported along with users
  As a Conjur user
  In order to keep track of which LDAP accounts correspond to Conjur users
  I want the imported Conjur users to have their uidnumber set to the LDAP account's uidNumber

  Background:
    Given LDAP database with:
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: <uids[alice]>
      gidNumber: <gids[users]>
      homeDirectory: /home/alice
      objectClass: posixAccount
      objectClass: top

      dn: uid=bob,dc=conjur,dc=net
      cn: Bob
      uid: bob
      uidNumber: <uids[bob]>
      gidNumber: <gids[users]>
      homeDirectory: /home/bob
      objectClass: posixAccount
      objectClass: top

      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: <gids[users]>
      objectClass: posixGroup
      objectClass: top

      dn: cn=admins,dc=conjur,dc=net
      cn: admins
      gidNumber: <gids[admins]>
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """
    
  Scenario: Users are imported with correct uidnumbers by default
    When I successfully sync
    Then a user named "<prefix>-alice" exists and has the uid for "alice"
    And a user named "<prefix>-bob" exists and has the uid for "bob"

  Scenario: Users do not have uids imported when sync gets --no-import-uid-numbers
    When I successfully sync with options "--no-import-uid-numbers"
    Then a user named "<prefix>-alice" exists and does not have the uid for "alice"
    And a user named "<prefix>-bob" exists and does not have the uid for "bob"