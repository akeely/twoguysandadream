package com.twoguysandadream.dal;

import com.mchange.v2.c3p0.*;
import static org.springframework.util.Assert.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.context.annotation.PropertySources;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;
import java.beans.PropertyVetoException;

/**
 * Created by andrew_keely on 2/17/15.
 */
@Configuration
@PropertySource("classpath:database.properties")
public class TestDatabaseConfig {

    @Value("${jdbc.driver}")
    private String jdbcDriver;
    @Value("${jdbc.url}")
    private String jdbcUrl;
    @Value("${jdbc.user}")
    private String jdbcUser;
    @Value("${jdbc.password}")
    private String jdbcPassword;
    @Value("${jdbc.connectionpool.min_size}")
    private int jdbcConnectionPoolMin;
    @Value("${jdbc.connectionpool.max_size}")
    private int jdbcConnectionPoolMax;
    @Value("${jdbc.connectionpool.acquire_increment}")
    private int jdbcConnectionPoolIncrement;

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }

    @Bean(destroyMethod = "close")
    public DataSource dataSource() throws PropertyVetoException {

        ComboPooledDataSource dataSource = new ComboPooledDataSource();

        dataSource.setDriverClass(jdbcDriver);
        dataSource.setJdbcUrl(jdbcUrl);
        dataSource.setUser(jdbcUser);
        dataSource.setPassword(jdbcPassword);
        dataSource.setMinPoolSize(jdbcConnectionPoolMin);
        dataSource.setMaxPoolSize(jdbcConnectionPoolMax);
        dataSource.setAcquireIncrement(jdbcConnectionPoolIncrement);

        return dataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate() throws PropertyVetoException {

        return new JdbcTemplate(dataSource());
    }
}
