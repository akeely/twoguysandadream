package com.twoguysandadream.config;


import com.twoguysandadream.resources.ApiConfiguration;
import com.twoguysandadream.security.OpenIdUserDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    static final String LOGIN_PAGE = "/login";

    @Autowired
    private OpenIdUserDetailsService userDetailsService;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable() // TODO: Figure this out!
            .logout()
                .logoutUrl("/logout")
                .logoutSuccessUrl(LOGIN_PAGE)
                .invalidateHttpSession(true)
                .and()
            .authorizeRequests()
            .antMatchers("/css/**").permitAll()
            .antMatchers("/img/**").permitAll()
            .antMatchers("/js/**").permitAll()
            .anyRequest().authenticated()
            .and()
            .openidLogin()
            .loginPage(LOGIN_PAGE)
            .permitAll()
            .defaultSuccessUrl("/auction")
            .authenticationUserDetailsService(userDetailsService)
            .attributeExchange("https://www.google.com/.*")
            .attribute("email")
            .type("http://axschema.org/contact/email")
            .required(true)
            .and()
            .attribute("firstname")
            .type("http://axschema.org/namePerson/first")
            .required(true)
            .and()
            .attribute("lastname")
            .type("http://axschema.org/namePerson/last")
            .required(true)
            .and()
            .and()
            .attributeExchange(".*yahoo.com.*")
            .attribute("email")
            .type("http://axschema.org/contact/email")
            .required(true)
            .and()
            .attribute("fullname")
            .type("http://axschema.org/namePerson")
            .required(true)
            .and()
            .and()
            .attributeExchange(".*myopenid.com.*")
            .attribute("email")
            .type("http://schema.openid.net/contact/email").required(true).and()
            .attribute("fullname").type("http://schema.openid.net/namePerson")
            .required(true);
    }
}
