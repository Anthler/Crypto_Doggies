import React, { Component } from "react";
import instance from "../contracts/cryptodoggies";
import web3 from "../web3/web3";

class Cards extends Component {
  state = {
    doggy: {},
    doggies: [],
    amount: 0,
    tokenSold: {},
    tokenSold: false
  };

  async componentWillMount() {
    await this.loaddoggies();
  }

  async loaddoggies() {
    let total = await instance.methods.totalSupply().call();

    for (let i = 0; i < total; i++) {
      const doggy = await this.loadDoggyDetails(i);
      this.setState({ doggies: [...this.state.doggies, doggy] });
    }
  }

  async loadDoggyDetails(id) {
    try {
      const dc = await instance.methods
        .getToken(id)
        .call({ from: instance.options.address });
      const dcJson = {
        id: id,
        name: dc[0],
        dna: dc[1],
        price: web3.utils.fromWei(dc[2], "ether"),
        nextPrice: web3.utils.fromWei(dc[3], "ether"),
        owner: dc[4]
      };
      return dcJson;
    } catch (error) {
      console.log(error);
    }
  }
  updatePrice = event => {
    this.setState({ amount: event.target.value });
  };

  handlePurchase = async tokenId => {
    try {
      const accounts = await web3.eth.getAccounts();
      const account = accounts[0];
      const price = await instance.methods.priceOf(tokenId).call();
      if (this.state.amount >= price) {
        const amount = this.state.amount;

        await instance.methods.purchase(tokenId).send({
          from: account,
          value: web3.utils.toWei(amount.toString(), "ether")
        });

        this.setState({ amount: 0 });
        this.setState({ tokenSold: true });
      } else {
        console.log(new Error("Invalid amount"));
      }
    } catch (error) {
      console.log(error);
    }
  };

  render() {
    return (
      <div className="row justify-content-center">
        {this.state.doggies.map(doggy => {
          return (
            <div key={doggy.id} className="col-md-4 align-content-center">
              <div className="card mb-5" style={{ width: "19rem" }}>
                <div className="row justify-content-center" key={doggy.id}>
                  <img
                    src={"www.jpg"}
                    className="card-img-top"
                    alt="Doggy image"
                  />
                  <div className="card-body">
                    <h5
                      className="card-title"
                      style={{
                        fontSize: 12,
                        color: "green",
                        fontWeight: "bold"
                      }}
                    >
                      Name: {doggy.name}{" "}
                    </h5>
                    <p
                      style={{
                        fontSize: 12,
                        color: "green",
                        fontWeight: "bold"
                      }}
                    >
                      DNA: {doggy.dna}{" "}
                    </p>
                    <p
                      className="card-text"
                      style={{
                        fontSize: 12,
                        color: "green",
                        fontWeight: "bold"
                      }}
                    >
                      {" "}
                      Next Price: Ξ {doggy.nextPrice}{" "}
                    </p>
                    <p
                      style={{
                        fontSize: 12,
                        color: "green",
                        fontWeight: "bold"
                      }}
                    >
                      Owner: {doggy.owner}{" "}
                    </p>
                    <p className="card-text">
                      <input
                        type="text"
                        className="form-control"
                        onChange={this.updatePrice}
                      />
                    </p>
                    <button
                      className="btn btn-primary btn-block"
                      onClick={() => this.handlePurchase(doggy.id)}
                    >
                      {" "}
                      BUY D0GGY{" "}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    );
  }
}

export default Cards;
