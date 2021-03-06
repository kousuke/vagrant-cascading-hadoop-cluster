class phoenix {
  $phoenix_version = "4.2.2"
  $hbase_version = "0.98.10"
  $phoenix_home = "/opt/phoenix-${phoenix_version}-bin"
  $phoenix_tarball = "phoenix-${phoenix_version}-bin.tar.gz"


  exec { "download_phoenix":
    command => "/tmp/grrr /phoenix/phoenix-${phoenix_version}/bin/$phoenix_tarball -O /vagrant/$phoenix_tarball --read-timeout=5 --tries=5",
    timeout => 1800,
    path => $path,
    creates => "/vagrant/$phoenix_tarball",
    require => [ Package["openjdk-7-jdk"], Exec["download_grrr"]]
  }

  exec { "unpack_phoenix" :
    command => "tar xf /vagrant/${phoenix_tarball} -C /opt",
    path => $path,
    creates => "${phoenix_home}",
    require => Exec["download_phoenix"]
  }
  
  exec { "remove_jar_of_phoenix" :
    command => "/bin/rm ${phoenix_home}/phoenix-${phoenix_version}-server.jar",
		require => Exec["unpack_phoenix"]
	}
  	
	file { "${phoenix_home}/phoenix-${phoenix_version}-server.jar":
		source => "puppet:///modules/phoenix/phoenix-${phoenix_version}-server.jar",
		ensure => file,
		mode => 644,
		owner => vagrant,
		group => vagrant,
		require => [Exec["remove_jar_of_phoenix"], Exec["unpack_hbase"]]
	}
	
	exec { "jar_copy_from_phoenix_to_hbase":
		command => "/bin/cp ${phoenix_home}/phoenix-${phoenix_version}-server.jar /opt/hbase-${hbase_version}-hadoop2/lib/",
		require => [Exec["remove_jar_of_phoenix"], Exec["unpack_hbase"], File["${phoenix_home}/phoenix-${phoenix_version}-server.jar"]]
	}
	
	exec { "change_owner_of_phoenix" :
    command => "/bin/chown -R vagrant.vagrant ${phoenix_home}",
		require => Exec["jar_copy_from_phoenix_to_hbase"]
	}
	

	file { "/etc/profile.d/phoenix-path.sh":
    content => template("phoenix/phoenix-path.sh.erb"),
    owner => root,
    group => root,
  }
}
