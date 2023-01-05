package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type request struct {
	Name string `json:"name"`
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		var req request
		err := json.NewDecoder(r.Body).Decode(&req)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		res, err := json.Marshal(map[string]string{
			"message": fmt.Sprintf("Hello %s", req.Name),
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.Write(res)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
