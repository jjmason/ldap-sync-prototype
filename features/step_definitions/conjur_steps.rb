Then(/^(?:the )?role "(.*?)" should exist$/) do |role|
  @last_role = @conjur.role(mangle_name role)
  @last_role.should exist
end

Then(/^it should (not )?be a member of "(.*?)"$/) do |neg, role|
  role = @conjur.role(mangle_name role)
  if neg
    expect(@last_role.member_of?(role)).to_not be_truthy
  else
    expect(@last_role.member_of?(role)).to be_truthy
  end
end


When %r{^I(?: can)?((?: not)|(?: successfully))? sync(?: with options "(.*)")?$} do |success, options|
  # TODO this is gross!
  set_environment_variable 'CONJUR_LDAP_SYNC_PREFIX', conjur_prefix
  command = mangle_name "./bin/conjur-ldap-sync #{options}"
  if success.strip == 'successfully'
    run_simple unescape(command), false
    unless last_command.exit_status == 0
      puts "failed to run #{command} | output => \n#{last_command.output}"
      assert_success true
    end
  else
    run_simple unescape(command), false
    if success.strip == 'not'
      assert_success false
    end
  end
end

Then %r{^it should (not )?be owned by "(.*?)"$} do |neg, owner|
  owner = "#{Conjur.account}:#{mangle_name(owner)}"
  kind = @last_role.kind
  ownerid = conjur.send(kind, @last_role.identifier).ownerid
  if neg
    expect(ownerid).to_not eq(owner)
  else
    expect(ownerid).to eq(owner)
  end
end

Then %r{the variable "(.*?)" should (not )?exist} do |name, neg|
  id = mangle_name(name)
  var = conjur.variable(id)
  if neg
    expect(var).to_not exist
  else
    expect(var).to exist
    expect(var.version_count).to be > 0
  end
  @last_variable_id = id
end

And %r{role "(.*?)" can execute the variable} do |role|
  role = conjur.role(mangle_name role)
  expect(role.permitted?("#{Conjur.account}:variable:#{@last_variable_id}", 'execute')).to be_truthy
end

Given %r{^a role named "(.*?)"$} do |rolename|
  roles_by_name[rolename] = find_or_create_role(rolename)
end

And %r{^I grant the service role to "(.*?)"$} do |role|
  role = conjur.role mangle_name(role)
  service_role.grant_to role
end

Then %r{^a user named "(.*?)" exists and has the uid for "(.*?)"} do |username, uidfor|
  uid = uids[uidfor]
  user = conjur.user(mangle_name username)
  expect(user).to exist
  expect(user.attributes['uidnumber'].to_s).to eq(uid.to_s)
end

Then %r{^a group named "(.*?)" exists and has the gid for "(.*?)"$} do |groupname, gidfor|
  gid = gids[gidfor]
  group = conjur.group mangle_name(groupname)
  expect(group).to exist
  expect(group.attributes['gidnumber'].to_s).to eq(gid.to_s)
end

Then %r{^the report should have actions:$} do |table|
  actual_reports = only_processes.last.stdout.split(/\n/).map{|l| JSON.parse(l)}
  expected_reports = expected_actions_from_table(table)
  expect(actual_reports.length).to eq(expected_reports.length)
  expected_reports.zip(actual_reports).each do |expected, actual|
    match_action expected, actual
  end
end

Then %r{^a group named "(.*?)" exists and does not have gid (\d+)} do |name, gid|
  group = conjur.group mangle_name(name)
  expect(group).to exist
  expect(group.attributes['gidnumber'].to_s).to_not eq(gid.to_s)
end


Then %r{^a user named "(.*?)" exists and does not have uid (\d+)} do |name, uid|
  user = conjur.user mangle_name(name)
  expect(user).to exist
  expect(user.attributes['gidnumber'].to_s).to_not eq(uid.to_s)
end
