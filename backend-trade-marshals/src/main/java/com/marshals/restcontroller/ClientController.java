package com.marshals.restcontroller;

import java.text.SimpleDateFormat;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.marshals.business.Client;
import com.marshals.business.LoggedInClient;
import com.marshals.business.services.ClientService;
import com.marshals.integration.DatabaseException;
import com.marshals.integration.FMTSException;


@RestController("clientController")
@RequestMapping("/client")
public class ClientController {

	private static final Logger logger = LoggerFactory.getLogger(ClientController.class);

	@Autowired
	private ClientService clientService;

	@GetMapping(value = "/ping")
	public String ping() {
		return "Client web service is alive at " + LocalDateTime.now();
	}


	// Register new client
	   @PostMapping(value = "/register", produces = { MediaType.APPLICATION_JSON_VALUE }, consumes = {
		   MediaType.APPLICATION_JSON_VALUE })
		public ResponseEntity<LoggedInClient> registerNewClient(@RequestBody Client client) {
		logger.info("[REGISTER] registerNewClient endpoint hit. Raw payload: {}", client);
		System.out.println("[REGISTER] registerNewClient endpoint hit. Raw payload: " + client);
			ResponseEntity<LoggedInClient> response = null;
			try {
				// Null checks for client and required fields
				if (client == null) {
					logger.error("[REGISTER] Client object is null");
					throw new NullPointerException("Client request body is null");
				}
				if (client.getEmail() == null || client.getEmail().trim().isEmpty() ||
					client.getPassword() == null || client.getPassword().trim().isEmpty() ||
					client.getName() == null || client.getName().trim().isEmpty() ||
					client.getCountry() == null || client.getCountry().trim().isEmpty() ||
					client.getDateOfBirth() == null ||
					client.getIdentification() == null || client.getIdentification().isEmpty()) {
					logger.error("[REGISTER] One or more required client fields are null or empty. Payload: {}", client);
					throw new IllegalArgumentException("One or more required client fields are missing");
				}
				SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");
				String dateOfBirth = dateFormat.format(client.getDateOfBirth());
				logger.info("[REGISTER] About to call clientService.registerNewClient");
				LoggedInClient newClient = clientService.registerNewClient(client.getEmail(), client.getPassword(),
					client.getName(), dateOfBirth, client.getCountry(), client.getIdentification());
				logger.info("[REGISTER] clientService.registerNewClient returned: {}", newClient);
				response = ResponseEntity.ok(newClient);
				logger.info("[REGISTER] Registration successful for email: {}", client.getEmail());
				return response;
			} catch (NullPointerException e) {
				logger.error("[REGISTER] NullPointerException: {} | Payload: {}", e.getMessage(), client, e);
				throw new ResponseStatusException(HttpStatus.NOT_ACCEPTABLE, e.getLocalizedMessage());
			} catch (IllegalArgumentException e) {
				logger.error("[REGISTER] IllegalArgumentException: {} | Payload: {}", e.getMessage(), client, e);
				throw new ResponseStatusException(HttpStatus.NOT_ACCEPTABLE, e.getLocalizedMessage());
			} catch (DatabaseException e) {
				logger.error("[REGISTER] DatabaseException: {} | Payload: {}", e.getMessage(), client, e);
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getLocalizedMessage());
			} catch (FMTSException e) {
				logger.error("[REGISTER] FMTSException: {} | Payload: {}", e.getMessage(), client, e);
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getLocalizedMessage());
			} catch (RuntimeException e) {
				logger.error("[REGISTER] RuntimeException: {} | Payload: {}", e.getMessage(), client, e);
				return ResponseEntity.internalServerError().build();
			}
	}

	// Login existing client - Send email and password as Query Params
	@GetMapping(produces = { MediaType.APPLICATION_JSON_VALUE })
	public ResponseEntity<LoggedInClient> loginExistingClient(@RequestParam String[] email, @RequestParam String[] password) {
		String actualEmail = (email.length > 0) ? email[0] : ""; // Safely get the first email
		String actualPassword = (password.length > 0) ? password[0] : ""; // Safely get the first password
		System.out.println("Email: " + actualEmail + "\nPassword: " + actualPassword);
		ResponseEntity<LoggedInClient> response = null;
		try {
//			if(email == null || password == null) {
//				throw new NullPointerException("Client login credentials are null");
//			}
			LoggedInClient newClient = clientService.loginExistingClient(actualEmail, actualPassword);
			response = ResponseEntity.ok(newClient); // 200
			return response;
		} catch (IllegalArgumentException e) { // 406
			   logger.error("Error in request for registering new client", e);
			   e.printStackTrace();
			throw new ResponseStatusException(HttpStatus.NOT_ACCEPTABLE, e.getLocalizedMessage());
		} catch (DatabaseException e) { // 404
			   logger.error("Error in request for registering new client", e);
			   e.printStackTrace();
			throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getLocalizedMessage());
		} catch (FMTSException e) { // 404
			   logger.error("Error in request for registering new client", e);
			   e.printStackTrace();
			throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getLocalizedMessage());
		} catch (RuntimeException e) { // Unexpected error - 500
			   logger.error("Problem occured from server", e);
			   e.printStackTrace();
			response = ResponseEntity.internalServerError().build();
			return response;
		}
	}
}
