package com.twoguysandadream.resources;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/owner")
public class OwnerResource {

    private final AuctionUserRepository auctionUserRepository;

    public OwnerResource(AuctionUserRepository auctionUserRepository) {
        this.auctionUserRepository = auctionUserRepository;
    }

    @GetMapping("/me")
    public Owner getOwner( @AuthenticationPrincipal AuctionUser user) {

        return auctionUserRepository.findOwner(user.getId().get())
                .map(Owner::new)
                .orElseThrow(() -> new IllegalStateException("Must be logged in."));
    }


    public static final class Owner {

        private final String name;

        public Owner(String name) {
            this.name = name;
        }

        public String getName() {
            return name;
        }
    }
}
