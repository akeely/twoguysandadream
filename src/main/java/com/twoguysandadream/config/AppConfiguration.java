package com.twoguysandadream.config;

import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.dal.LeagueDao;
import com.twoguysandadream.resources.legacy.AuctionBoard;
import org.springframework.beans.factory.annotation.Autowired;
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

        return new LeagueDao(namedParameterJdbcTemplate);
    }

    @Autowired
    private NamedParameterJdbcTemplate namedParameterJdbcTemplate;

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }
}
