package com.twoguysandadream.config;

import org.apache.commons.dbcp2.BasicDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import javax.sql.DataSource;

/**
 * Created by andrewk on 3/12/15.
 */
@Configuration
public class DataSourceConfiguration {

    @Bean
    public DataSource dataSource() {

        BasicDataSource dataSource = new BasicDataSource();
        dataSource.setDriverClassName("com.mysql.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql://192.168.33.10:3306/auction");
        dataSource.setUsername("uat");
        dataSource.setPassword("password");

        return dataSource;
    }

    @Bean
    public NamedParameterJdbcTemplate jdbcTemplate() {

        return new NamedParameterJdbcTemplate(dataSource());
    }
}
