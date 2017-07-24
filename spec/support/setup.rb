module Test
  def self.setup(database_url)
    const_set('CONF', ROM::Configuration.new(:sql, database_url))
    CONF.register_relation(Test::UserRelation)
    CONF.register_relation(Test::TaskRelation)

    const_set('ROM', ROM.container(CONF))

    const_set('CONN', CONF.gateways[:default].connection)
  end
end
