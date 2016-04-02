package com.twoguysandadream.config;

import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.resources.legacy.AuctionBoard;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;

@Configuration
@PropertySource("classpath:twoguysandadream-queries.xml")
@ComponentScan("com.twoguysandadream.dal")
public class AppConfiguration {

    @Bean
    public AuctionBoard auctionBoard(LeagueRepository leagueRepository) {

        return new AuctionBoard(leagueRepository);
    }

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }
}
