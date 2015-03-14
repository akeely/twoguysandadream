package com.twoguysandadream.config;

import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.dal.LeagueDao;
import com.twoguysandadream.resources.legacy.AuctionBoard;
import org.apache.commons.dbcp2.BasicDataSource;
import org.springframework.context.annotation.*;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import javax.sql.DataSource;

/**
 * Created by andrewk on 3/13/15.
 */
@Configuration
//@Import(DataSourceConfiguration.class)
@PropertySource("classpath:twoguysandadream-queries.properties")
public class AppConfiguration {

    @Bean
    public AuctionBoard auctionBoard() {

        return new AuctionBoard(leagueRepository());
    }

    @Bean
    public LeagueRepository leagueRepository() {

        return new LeagueDao(namedParameterJdbcTemplate());
    }

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
    public NamedParameterJdbcTemplate namedParameterJdbcTemplate() {

        return new NamedParameterJdbcTemplate(dataSource());
    }

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }
}
