package com.twoguysandadream.config;

import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.dal.LeagueDao;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

/**
 * Created by andrewk on 3/13/15.
 */
@Configuration
@Import(DataSourceConfiguration.class)
@ComponentScan("com.twoguysandadream")
public class AppConfiguration {

    @Bean
    public LeagueRepository leagueRepository() {
        return new LeagueDao();
    }
}
