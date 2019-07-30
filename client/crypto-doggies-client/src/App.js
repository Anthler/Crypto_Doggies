import React, { Component } from "react";
import "./App.css";
import instance from "./contracts/cryptodoggies";
import web3 from "./web3/web3";

import Cards from "./components/Card";
import SearchAppBar from "./components/Header";

class App extends Component {
  state = {
    contAddr: "",
    account: "",
    totalSupply: 0,
    name: ""
  };

  async componentWillMount() {
    await this.setState({ contAddr: instance.options.address });

    this.getAccount();
    this.getTotalSupply();
  }

  async getTotalSupply() {
    try {
      const accounts = await web3.eth.getAccounts();
      const account = accounts[0];
      const totalSupply = await instance.methods
        .totalSupply()
        .call({ from: account });
      this.setState({ totalSupply: totalSupply });
    } catch (error) {
      console.log(error);
    }
  }

  async getAccount() {
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];
    this.setState({ account });
  }

  render() {
    return (
      <div className="App ">
        <SearchAppBar />
        <div className="container ">
          <div className="row justify-content-center">
            <div className="col-md-5">
              <h5>Contract Address: {this.state.contAddr}</h5>
            </div>
            <h5 className="col-md-5">
              Admin Address: {this.state.account}
              {this.state.totalSupply}
            </h5>
          </div>
          <br />
          <div className="row d-flex flex-row justify-content-center ">
            <div className="col-md-6">
              <h5>Available CryptoDoggies</h5>
            </div>
          </div>
          <br />
          <Cards />
        </div>
      </div>
    );
  }
}

export default App;
