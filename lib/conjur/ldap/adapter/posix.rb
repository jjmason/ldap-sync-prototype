class Conjur::Ldap::Adapter
  class Posix < self
    register_adapter_class :posix

    def default_user_object_classes
      %w(posixAccount)
    end

    def default_group_object_classes
      %w(posixGroup)
    end

    def load_model
      groups_by_gid = {}
      find_groups.map{|branch| group_from_branch(branch)}.each do |group|
        groups_by_gid[group.gid] = group
      end

      users_by_name = {}
      find_users.map{|branch| user_from_branch(branch)}.each do |user|
        users_by_name[user.name] = user
      end

      groups = groups_by_gid.values
      users  = users_by_name.values

      groups.each do |group|
        group.members.map!{|m| users_by_name[name] }
      end

      users.each do |user|
        user.groups.map!{|g| groups_by_gid[g]}
      end

      model users, groups
    end

    def group_from_branch branch
      name = first_of(branch['cn'])
      gid  = first_of(branch['gidnumber']).to_i
      group(name,nil,gid).tap do |g|
        array_of(branch['members']).each{|uid| g.members << uid}
      end
    end

    def user_from_branch branch
      puts "user_from_branch: #{branch.inspect}"
      puts "uid is #{branch['uid']}"
      puts "uid of entry is #{branch.entry['uid']}"
      name = first_of(branch['uid'])
      uid  = first_of(branch['uidnumber']).to_i
      user(name, nil, uid).tap do |u|
        array_of(branch['gidnumber']).each{ |gid| u.groups << gid }
      end
    end

    private
    def first_of val
      puts "first_of #{val} (array? #{val.kind_of?(Array)} fst=#{val.first})"
      (val.kind_of?(Array) ? val.first : val).tap do |v|
        raise 'missing value' if v.nil?
      end
    end

    def array_of thing
      thing.kind_of?(Array) ? thing : [thing].compact
    end
  end
end