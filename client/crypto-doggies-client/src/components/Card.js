import React, { Component } from "react";
import instance from "../contracts/cryptodoggies";
import web3 from "../web3/web3";

class Cards extends Component {
  state = {
    doggy: {},
    doggies: [],
    amount: 0,
    tokenSold: {},
    confirmed: false
  };

  async componentWillMount() {
    await this.loaddoggies();
  }

  async loaddoggyes() {
    let total = await instance.methods.totalSupply().call();

    for (let i = 0; i < total; i++) {
      const doggy = await this.loadDoggyDetails(i);
      this.setState({ doggies: [...this.state.doggies, doggy] });
      //console.log(this.state.doggyes);
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
        instance.once(
          "TokenSold",
          {
            filter: {},
            fromBlock: 0
          },
          function(error, event) {
            let tokenSold = event.returnValues;
            // const eventObject = {
            //   tokenId: event.returnValues[0],
            //   tokenName: event.returnValues[1],
            //   dna: event.returnValues[2],
            //   sellingPrice: event.returnValues[3],
            //   price: event.returnValues[4],
            //   oldOwner: event.returnValues[5],
            //   newOwner: event.returnValues[6]
            // };

            // this.setState({
            //   confirmed: true,
            //   tokenSold: event.returnValues
            // });
            console.log(event);
            console.log(tokenSold.dna);
            //console.log(typeof event.returnValues);
            //console.log(eventObject);
            //return eventObject;
          }
        );
        this.setState({ amount: 0 });
      } else {
        console.log(new Error("Invalid amount"));
      }
    } catch (error) {
      console.log(error);
    }
  };

  render() {
    return (
      <div className="row text-center">
        {this.state.doggies.map(doggy => {
          return (
            <div key={doggy.id} className="col-md-4">
              <div className="card" style={{ width: "18rem" }}>
                <div className="row" key={doggy.id}>
                  <img
                    src={"www.jpg"}
                    className="card-img-top"
                    alt="Doggy image"
                  />
                  <div className="card-body">
                    <h5 className="card-title">Name: {doggy.name} </h5>
                    <p>DNA: {doggy.dna} </p>
                    {/* <p className="card-text">Price: Ξ {doggy.price} </p> */}

                    <p className="card-text">
                      {" "}
                      Next Price: Ξ {doggy.nextPrice}{" "}
                    </p>
                    <p style={{ fontSize: 12 }}>Owner: {doggy.owner} </p>
                    <p className="card-text">
                      <input
                        type="text"
                        className="form-control"
                        onChange={this.updatePrice}
                      />
                    </p>
                    <button
                      className="btn btn-primary"
                      onClick={() => this.handlePurchase(doggy.id)}
                    >
                      {" "}
                      Buy{" "}
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
